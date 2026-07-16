-- Identidad del vecino (BT-13). Decisión 14: primero riega, después crea la
-- cuenta. Acá vive el puente entre las dos: el perfil se crea solo al
-- registrarse, y reclamar_riegos adopta los riegos que el teléfono hizo
-- anónimo, con sus puntos y las insignias que correspondan.

-- ---------- perfil automático al crear la cuenta ----------
-- Sin esto el vecino se loguea y no existe como jugador. El nombre sale de
-- Google si vino por ahí; si entró con enlace mágico, del mail.
create function crear_perfil_para_usuario() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into perfiles (id, nombre)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Vecino'
    )
  )
  on conflict (id) do nothing;
  return new;
end $$;

create trigger crear_perfil_al_registrarse
  after insert on auth.users
  for each row execute function crear_perfil_para_usuario();

-- ---------- otorgamiento de insignias (una sola fuente) ----------
-- Estaba embebido en registrar_riego; ahora lo comparten el riego y el
-- reclamo. Evalúa escalera (por puntos acumulados) + méritos (por criterio)
-- e inserta las que falten. Devuelve solo las nuevas, con su copy.
create function otorgar_insignias(p_perfil uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_total integer;
  v_tz text := 'America/Argentina/Buenos_Aires';
  v_nuevas jsonb;
begin
  select puntos into v_total from perfiles where id = p_perfil;
  if v_total is null then
    return '[]'::jsonb;
  end if;

  with candidatas as (
    select i.id from insignias i
    where i.activa
      and (
        (i.tipo = 'escalera' and i.umbral_puntos <= v_total)
        or (i.id = 'rescatista'
            and (select count(*) from riegos r
                 where r.perfil_id = p_perfil and r.estado_al_regar = 'muy_sediento')
                >= (select (valor)::integer from config where clave = 'rescatista_n'))
        or (i.id = 'madrugador'
            and (select count(*) from riegos r
                 where r.perfil_id = p_perfil
                   and extract(hour from r.creado_en at time zone v_tz)
                       < (select (valor)::integer from config where clave = 'madrugador_hora_limite'))
                >= (select (valor)::integer from config where clave = 'madrugador_n'))
        or (i.id = 'sereno'
            and (select count(*) from riegos r
                 where r.perfil_id = p_perfil
                   and extract(hour from r.creado_en at time zone v_tz)
                       >= (select (valor)::integer from config where clave = 'sereno_hora_inicio'))
                >= (select (valor)::integer from config where clave = 'sereno_n'))
      )
      and not exists (select 1 from insignias_ganadas g
                      where g.perfil_id = p_perfil and g.insignia_id = i.id)
  ), ins as (
    insert into insignias_ganadas (perfil_id, insignia_id)
    select p_perfil, id from candidatas
    returning insignia_id
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', i.id, 'nombre', i.nombre, 'copy', i.copy_desbloqueo)), '[]'::jsonb)
  into v_nuevas
  from ins join insignias i on i.id = ins.insignia_id;

  return v_nuevas;
end $$;

-- ---------- registrar_riego: ahora delega las insignias ----------
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

  -- El cooldown del vecino mira las dos identidades: si se logueó recién, sus
  -- riegos viejos siguen atados al dispositivo. Cerrar sesión no habilita a
  -- repetir el mismo árbol.
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

  -- El dispositivo se guarda siempre (rastro para el reclamo y para el
  -- cooldown); el perfil solo si hay sesión.
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

-- ---------- reclamo del riego anónimo ----------
-- El vecino regó sin cuenta; al registrarse, sus riegos pasan a su nombre.
-- Solo se adoptan riegos huérfanos (perfil_id null): una vez reclamados por
-- alguien, nadie más puede tomarlos.
create function reclamar_riegos(p_dispositivo_id text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_perfil uuid := auth.uid();
  v_cantidad integer := 0;
  v_puntos integer := 0;
  v_total integer;
  v_nuevas jsonb := '[]'::jsonb;
begin
  if v_perfil is null then
    return jsonb_build_object('ok', false, 'motivo', 'sin_sesion');
  end if;
  if p_dispositivo_id is null or length(p_dispositivo_id) < 8 then
    return jsonb_build_object('ok', false, 'motivo', 'sin_dispositivo');
  end if;

  -- Un reclamo a la vez por dispositivo (dos pestañas no duplican puntos).
  perform pg_advisory_xact_lock(hashtext(p_dispositivo_id));

  with reclamados as (
    update riegos set perfil_id = v_perfil
    where dispositivo_id = p_dispositivo_id and perfil_id is null
    returning puntos
  )
  select count(*), coalesce(sum(puntos), 0) into v_cantidad, v_puntos from reclamados;

  if v_cantidad = 0 then
    return jsonb_build_object('ok', true, 'riegos', 0, 'puntos', 0, 'insignias_nuevas', '[]'::jsonb);
  end if;

  update perfiles set puntos = puntos + v_puntos where id = v_perfil
  returning puntos into v_total;

  v_nuevas := otorgar_insignias(v_perfil);

  return jsonb_build_object(
    'ok', true,
    'riegos', v_cantidad,
    'puntos', v_puntos,
    'total_puntos', v_total,
    'insignias_nuevas', v_nuevas
  );
end $$;
