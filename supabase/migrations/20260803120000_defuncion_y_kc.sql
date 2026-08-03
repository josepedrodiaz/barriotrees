-- Defunción del árbol + Kc por especie (BT-41, observatorio agronómico).
--
-- Dos datos que faltaban para que el juego rinda métricas serias:
--  · fecha_defuncion: null = vivo. Convierte el registro de riegos en un
--    registro de SUPERVIVENCIA, que es la métrica que de verdad le importa al
--    agrónomo (¿el programa mantiene vivos a los árboles jóvenes?).
--  · kc: coeficiente de cultivo (FAO-56). ETc = Kc × ET0 = necesidad hídrica
--    real de la especie. Con esto el balance pasa de "déficit genérico" a
--    "cuánta agua necesita ESTA especie".

alter table arboles add column if not exists fecha_defuncion date;
alter table arboles add column if not exists causa_defuncion text;

-- 0.7 es un valor razonable de árbol joven en establecimiento; a validar con la
-- comisión de arbolado, como se hizo con los umbrales.
alter table especies add column if not exists kc numeric not null default 0.7;

-- La vista se recrea para exponer fecha_defuncion (viene por a.*, que se
-- "congela" al crear la vista, así que hay que recrearla).
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
  coalesce((select sum(c.lluvia_mm) from clima_diario c where c.fecha > current_date - 3), 0) as lluvia_3d
from arboles a
join especies e on e.id = a.especie_id
cross join lateral f_estado_arbol(a.id) st
where a.activo;

-- Un árbol muerto no se riega: guard en el corazón anti-trampa. Misma función
-- que en 20260715230000, con un chequeo agregado después de encontrar el árbol.
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
