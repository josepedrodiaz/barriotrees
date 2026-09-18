-- No mandar a regar sobre suelo mojado / barrial (BT: riego suelo mojado).
--
-- El balance hídrico (BT-33) mide la sed de MEDIANO plazo (mm de déficit
-- acumulado), pero no sabe si el suelo está encharcado AHORA. Un árbol puede
-- seguir con déficit de fondo y, tras una lluvia, tener la superficie saturada:
-- regar ahí es tirar agua sobre barro, no absorbe y molesta al vecino.
--
-- La señal: humedad de suelo real (0–7 cm) de Open-Meteo. Es un dato de ESTADO
-- (m³/m³ de agua en el suelo, no lluvia caída) que ya integra lluvia +
-- evaporación + tipo de suelo del modelo, y se autoajusta a la estación solo
-- (en enero el suelo seca rápido, en julio lento — el dato ya lo refleja). Por
-- eso reemplaza al "excedente inferido del balance": no lo estimamos, lo leemos.

-- ---------- la humedad de suelo, un valor instantáneo por día ----------
-- La escribe el cron horario (clima.yml) en la fila del día de hoy; cada hora
-- la pisa con el último valor. Es global de la plaza (una coordenada), como la
-- lluvia. Nullable: si falta el dato, no frenamos (el freno degrada a "no
-- saturado", igual que el balance degrada al reloj cuando falta clima).
alter table clima_diario add column if not exists humedad_suelo numeric;
comment on column clima_diario.humedad_suelo is
  'Humedad volumétrica del suelo 0–7 cm (m³/m³) de Open-Meteo, último valor horario del día. null = sin dato.';

-- ---------- umbral de "no vale la pena regar" (editable por admin) ----------
-- 0.38 m³/m³ ≈ capacidad de campo de un suelo franco-arcilloso (La Plata).
-- Por encima, el suelo está cerca de saturación: barro, no absorbe más. Es el
-- número a CALIBRAR con el mail post-lluvia (Tanda B) yendo a ver la plaza.
insert into config (clave, valor, descripcion) values
  ('humedad_suelo_saturado', '0.38',
   'Humedad de suelo (m³/m³, Open-Meteo 0–7 cm) desde la cual NO se manda a regar: el suelo está mojado/barro y no absorbe. ~capacidad de campo de suelo franco-arcilloso. Calibrable con la salida a la plaza.')
on conflict (clave) do nothing;

-- ---------- ¿el suelo de la plaza está saturado AHORA? ----------
-- Última humedad conocida vs. umbral. null (sin dato) => false: no frenamos por
-- falta de dato. Se factoriza acá para que la vista y la RPC de riego usen
-- exactamente la misma regla.
create function f_suelo_saturado()
returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(
    (select c.humedad_suelo from clima_diario c
       where c.humedad_suelo is not null
       order by c.fecha desc limit 1)
    >= (select (valor)::numeric from config where clave = 'humedad_suelo_saturado'),
    false);
$$;

-- ---------- la ingesta ahora guarda la humedad ----------
-- Un parámetro más, opcional: el cron lo manda solo para el día de hoy (el
-- valor instantáneo actual); los días pasados van con null.
-- Agregar p_humedad cambia la firma, así que create or replace no pisa la
-- versión de 5 args: hay que dropearla o quedan las dos y PostgREST no sabe
-- cuál llamar (PGRST203).
drop function if exists registrar_clima(text, date, numeric, numeric, numeric);
create or replace function registrar_clima(
  p_token text,
  p_fecha date,
  p_lluvia numeric,
  p_et0 numeric,
  p_temp numeric default null,
  p_humedad numeric default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  if p_token is null or p_token <> (select valor from secretos where clave = 'clima_token') then
    return jsonb_build_object('ok', false, 'motivo', 'no_autorizado');
  end if;

  insert into clima_diario (fecha, lluvia_mm, et0_mm, temp_max, humedad_suelo)
  values (p_fecha, coalesce(p_lluvia, 0), coalesce(p_et0, 0), p_temp, p_humedad)
  on conflict (fecha) do update
    set lluvia_mm = excluded.lluvia_mm,
        et0_mm = excluded.et0_mm,
        temp_max = excluded.temp_max,
        -- Solo pisa la humedad si vino un valor: no borrar el de hoy con el
        -- null de una re-carga de días pasados.
        humedad_suelo = coalesce(excluded.humedad_suelo, clima_diario.humedad_suelo),
        creado_en = now();

  return jsonb_build_object('ok', true, 'fecha', p_fecha);
end $$;

-- ---------- la vista expone la humedad y el flag ----------
drop view v_arboles_estado;
create view v_arboles_estado as
select
  a.*,
  e.nombre_comun as especie_nombre,
  e.nombre_cientifico as especie_cientifico,
  e.en_programa,
  st.f_efectiva,
  st.dias_sin_riego,
  st.estado,
  round(f_deficit_mm(a.id), 1) as deficit_mm,
  coalesce((select sum(c.lluvia_mm) from clima_diario c where c.fecha > current_date - 3), 0) as lluvia_3d,
  (select c.humedad_suelo from clima_diario c
     where c.humedad_suelo is not null order by c.fecha desc limit 1) as humedad_suelo,
  f_suelo_saturado() as suelo_saturado
from arboles a
join especies e on e.id = a.especie_id
cross join lateral f_estado_arbol(a.id) st
where a.activo;

-- ---------- el freno vive en el servidor (anti-trampa) ----------
-- Mismo cuerpo que en 20260803120000, con un guard más: suelo saturado rechaza
-- el riego antes de tocar nada. Va con los otros guards de "este árbol no se
-- riega ahora" (muerto, lejos, cooldown), como motivo propio para que el front
-- muestre el mensaje correcto.
create or replace function registrar_riego(
  p_codigo text,
  p_dispositivo_id text default null,
  p_lat double precision default null,
  p_lng double precision default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_arbol arboles%rowtype;
  v_perfil uuid := auth.uid();
  v_estado estado_arbol;
  v_puntos integer;
  v_total integer;
  v_radio numeric := (select (valor)::numeric from config where clave = 'radio_proximidad_metros');
  v_cd_arbol numeric := (select (valor)::numeric from config where clave = 'cooldown_arbol_horas');
  v_cd_vecino numeric := (select (valor)::numeric from config where clave = 'cooldown_vecino_arbol_horas');
  v_ultimo timestamptz;
  v_ultimo_mio timestamptz;
  v_dist numeric;
  v_nuevas jsonb := '[]'::jsonb;
begin
  if v_perfil is null and (p_dispositivo_id is null or length(p_dispositivo_id) < 8) then
    return jsonb_build_object('ok', false, 'motivo', 'sin_autor');
  end if;

  select * into v_arbol from arboles where codigo = p_codigo and activo;
  if not found then
    return jsonb_build_object('ok', false, 'motivo', 'arbol_inexistente');
  end if;

  if v_arbol.fecha_defuncion is not null then
    return jsonb_build_object('ok', false, 'motivo', 'arbol_muerto');
  end if;

  -- Llovió y el suelo está mojado: no se riega, aunque el árbol tenga sed de
  -- fondo. Es global de la plaza, así que no depende de qué árbol se escanee.
  if f_suelo_saturado() then
    return jsonb_build_object('ok', false, 'motivo', 'suelo_saturado');
  end if;

  perform pg_advisory_xact_lock(hashtext(v_arbol.id::text));

  if v_arbol.lat is not null and v_arbol.lng is not null then
    if p_lat is null or p_lng is null then
      return jsonb_build_object('ok', false, 'motivo', 'sin_ubicacion');
    end if;
    v_dist := 2 * 6371000 * asin(sqrt(
      power(sin(radians(p_lat - v_arbol.lat) / 2), 2)
      + cos(radians(v_arbol.lat)) * cos(radians(p_lat))
        * power(sin(radians(p_lng - v_arbol.lng) / 2), 2)));
    if v_dist > v_radio then
      return jsonb_build_object('ok', false, 'motivo', 'lejos', 'distancia_m', round(v_dist));
    end if;
  end if;

  select max(creado_en) into v_ultimo from riegos where arbol_id = v_arbol.id;
  if v_ultimo is not null and v_ultimo > now() - (v_cd_arbol || ' hours')::interval then
    return jsonb_build_object('ok', false, 'motivo', 'cooldown_arbol',
      'proximo_riego', v_ultimo + (v_cd_arbol || ' hours')::interval);
  end if;

  select max(creado_en) into v_ultimo_mio from riegos
  where arbol_id = v_arbol.id
    and ((v_perfil is not null and perfil_id = v_perfil)
      or (p_dispositivo_id is not null and dispositivo_id = p_dispositivo_id));
  if v_ultimo_mio is not null and v_ultimo_mio > now() - (v_cd_vecino || ' hours')::interval then
    return jsonb_build_object('ok', false, 'motivo', 'cooldown_vecino',
      'proximo_riego', v_ultimo_mio + (v_cd_vecino || ' hours')::interval);
  end if;

  select estado into v_estado from f_estado_arbol(v_arbol.id);
  v_puntos := coalesce(((select valor from config where clave = 'puntos_riego') ->> v_estado::text)::integer, 0);

  insert into riegos (arbol_id, perfil_id, dispositivo_id, estado_al_regar, puntos, lat, lng)
  values (v_arbol.id, v_perfil, p_dispositivo_id, v_estado, v_puntos, p_lat, p_lng);

  if v_perfil is not null then
    update perfiles set puntos = puntos + v_puntos where id = v_perfil
    returning puntos into v_total;
    v_nuevas := otorgar_insignias(v_perfil);
  end if;

  return jsonb_build_object(
    'ok', true,
    'puntos', v_puntos,
    'total_puntos', v_total,
    'estado_anterior', v_estado,
    'insignias_nuevas', v_nuevas
  );
end $$;
