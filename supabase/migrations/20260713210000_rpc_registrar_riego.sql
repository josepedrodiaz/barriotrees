-- RPC registrar_riego: la única puerta de entrada para sumar riegos, puntos
-- e insignias (docs/arquitectura.md, principio 3). El cliente no puede
-- escribir nada de esto directo — acá viven los cooldowns, la proximidad
-- y el otorgamiento, en una sola transacción.

-- Estado actual de un árbol (mismo cálculo que v_arboles_estado, reutilizable).
create function f_estado_arbol(p_arbol_id uuid)
returns table (estado estado_arbol, dias_sin_riego numeric, f_efectiva numeric)
language sql stable security definer set search_path = public as $$
  with datos as (
    select
      coalesce(a.frecuencia_dias_override, e.frecuencia_dias)
        * coalesce((select (valor)::numeric from config where clave = 'multiplicador_estacional'), 1) as f,
      (select max(r.creado_en) from riegos r where r.arbol_id = a.id) as ultimo
    from arboles a join especies e on e.id = a.especie_id
    where a.id = p_arbol_id
  )
  select
    case
      when ultimo is null then 'muy_sediento'::estado_arbol
      when extract(epoch from (now() - ultimo)) / 86400.0
        <= f * coalesce((select (valor)::numeric from config where clave = 'banda_feliz'), 0.5) then 'feliz'
      when extract(epoch from (now() - ultimo)) / 86400.0
        <= f * coalesce((select (valor)::numeric from config where clave = 'banda_bien'), 1) then 'bien'
      when extract(epoch from (now() - ultimo)) / 86400.0
        <= f * coalesce((select (valor)::numeric from config where clave = 'banda_sediento'), 2) then 'sediento'
      else 'muy_sediento'
    end,
    extract(epoch from (now() - ultimo)) / 86400.0,
    f
  from datos;
$$;

create function registrar_riego(
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
  v_tz text := 'America/Argentina/Buenos_Aires';
begin
  if v_perfil is null and (p_dispositivo_id is null or length(p_dispositivo_id) < 8) then
    return jsonb_build_object('ok', false, 'motivo', 'sin_autor');
  end if;

  select * into v_arbol from arboles where codigo = p_codigo and activo;
  if not found then
    return jsonb_build_object('ok', false, 'motivo', 'arbol_inexistente');
  end if;

  -- Un riego a la vez por árbol (evita carrera de dos escaneos simultáneos).
  perform pg_advisory_xact_lock(hashtext(v_arbol.id::text));

  -- Proximidad: solo exigible si el árbol tiene coordenadas cargadas.
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

  -- Cooldown del árbol (alguien ya lo regó hace poco).
  select max(creado_en) into v_ultimo from riegos where arbol_id = v_arbol.id;
  if v_ultimo is not null and v_ultimo > now() - (v_cd_arbol || ' hours')::interval then
    return jsonb_build_object('ok', false, 'motivo', 'cooldown_arbol',
      'proximo_riego', v_ultimo + (v_cd_arbol || ' hours')::interval);
  end if;

  -- Cooldown vecino+árbol (el mismo autor no repite este árbol).
  select max(creado_en) into v_ultimo_mio from riegos
  where arbol_id = v_arbol.id
    and ((v_perfil is not null and perfil_id = v_perfil)
      or (v_perfil is null and dispositivo_id = p_dispositivo_id));
  if v_ultimo_mio is not null and v_ultimo_mio > now() - (v_cd_vecino || ' hours')::interval then
    return jsonb_build_object('ok', false, 'motivo', 'cooldown_vecino',
      'proximo_riego', v_ultimo_mio + (v_cd_vecino || ' hours')::interval);
  end if;

  -- Estado ANTES de regar → determina los puntos.
  select estado into v_estado from f_estado_arbol(v_arbol.id);
  v_puntos := coalesce(((select valor from config where clave = 'puntos_riego') ->> v_estado::text)::integer, 0);

  insert into riegos (arbol_id, perfil_id, dispositivo_id, estado_al_regar, puntos, lat, lng)
  values (v_arbol.id, v_perfil, case when v_perfil is null then p_dispositivo_id end, v_estado, v_puntos, p_lat, p_lng);

  -- Con cuenta: acumular puntos y otorgar insignias. (Anónimo: los puntos
  -- quedan en el riego y se reclaman al crear la cuenta — BT-13.)
  if v_perfil is not null then
    update perfiles set puntos = puntos + v_puntos where id = v_perfil
    returning puntos into v_total;

    with candidatas as (
      select i.id from insignias i
      where i.activa
        and (
          (i.tipo = 'escalera' and i.umbral_puntos <= v_total)
          or (i.id = 'rescatista'
              and (select count(*) from riegos r where r.perfil_id = v_perfil and r.estado_al_regar = 'muy_sediento')
                  >= (select (valor)::integer from config where clave = 'rescatista_n'))
          or (i.id = 'madrugador'
              and (select count(*) from riegos r where r.perfil_id = v_perfil
                     and extract(hour from r.creado_en at time zone v_tz)
                         < (select (valor)::integer from config where clave = 'madrugador_hora_limite'))
                  >= (select (valor)::integer from config where clave = 'madrugador_n'))
          or (i.id = 'sereno'
              and (select count(*) from riegos r where r.perfil_id = v_perfil
                     and extract(hour from r.creado_en at time zone v_tz)
                         >= (select (valor)::integer from config where clave = 'sereno_hora_inicio'))
                  >= (select (valor)::integer from config where clave = 'sereno_n'))
        )
        and not exists (select 1 from insignias_ganadas g
                        where g.perfil_id = v_perfil and g.insignia_id = i.id)
    ), ins as (
      insert into insignias_ganadas (perfil_id, insignia_id)
      select v_perfil, id from candidatas
      returning insignia_id
    )
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', i.id, 'nombre', i.nombre, 'copy', i.copy_desbloqueo)), '[]'::jsonb)
    into v_nuevas
    from ins join insignias i on i.id = ins.insignia_id;
  end if;

  return jsonb_build_object(
    'ok', true,
    'puntos', v_puntos,
    'total_puntos', v_total,
    'estado_anterior', v_estado,
    'insignias_nuevas', v_nuevas
  );
end $$;

-- ---------- carga inicial: los 10 jacarandás de la galería central ----------
-- Sin coordenadas por ahora (se cargan con el relevamiento / admin BT-19);
-- mientras un árbol no tenga lat/lng la validación de proximidad no aplica.
insert into arboles (codigo, especie_id, sector)
select 'jaca-' || lpad(n::text, 2, '0'),
       (select id from especies where nombre_comun = 'Jacarandá'),
       'galeria-central'
from generate_series(1, 10) as n;
