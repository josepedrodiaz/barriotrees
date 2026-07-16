-- Canje de pines (BT-21): la mecánica de entrega del evento del 21/09.
-- El vecino muestra el QR de su insignia, el de la comisión lo escanea y el
-- sistema lo marca entregado. Imposible cobrarlo dos veces, sin listas en
-- papel (decisión 18).

-- ---------- primero, tapar una gotera ----------
-- La policy de lectura pública de BT-10 exponía canje_token a cualquiera con
-- la clave pública: un ticket de canje que todo el mundo puede leer no es un
-- ticket. Hoy no es explotable (solo un admin puede canjear), pero el token
-- deja de ser público ahora y no cuando duela.
-- RLS es por fila, así que la columna se cierra con permisos de columna.
revoke select (canje_token) on insignias_ganadas from anon, authenticated;

-- ---------- el vecino ve SOLO sus tokens ----------
create function mis_canjes()
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_perfil uuid := auth.uid();
begin
  if v_perfil is null then
    return jsonb_build_object('ok', false, 'motivo', 'sin_sesion');
  end if;
  return jsonb_build_object(
    'ok', true,
    'canjes', coalesce((
      select jsonb_agg(jsonb_build_object(
        'insignia_id', g.insignia_id,
        'nombre', i.nombre,
        'estado', g.canje_estado,
        'token', g.canje_token,
        'canjeada_en', g.canjeada_en
      ) order by g.ganada_en)
      from insignias_ganadas g
      join insignias i on i.id = g.insignia_id
      where g.perfil_id = v_perfil and i.es_pin
    ), '[]'::jsonb)
  );
end $$;

-- ---------- el validador mira antes de entregar ----------
-- Leer no entrega: primero la comisión ve de quién es y qué es, y recién
-- después confirma. Si ya se entregó, lo dice con fecha.
create function ver_canje(p_token uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_fila record;
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;

  select g.canje_estado, g.canjeada_en, g.ganada_en, i.nombre as insignia,
         p.nombre as vecino, q.nombre as entregado_por
  into v_fila
  from insignias_ganadas g
  join insignias i on i.id = g.insignia_id
  join perfiles p on p.id = g.perfil_id
  left join perfiles q on q.id = g.canjeada_por
  where g.canje_token = p_token;

  if not found then
    return jsonb_build_object('ok', false, 'motivo', 'inexistente');
  end if;

  return jsonb_build_object(
    'ok', true,
    'estado', v_fila.canje_estado,
    'insignia', v_fila.insignia,
    'vecino', v_fila.vecino,
    'ganada_en', v_fila.ganada_en,
    'canjeada_en', v_fila.canjeada_en,
    'entregado_por', v_fila.entregado_por
  );
end $$;

-- ---------- entregar el pin ----------
-- El update lleva la condición del estado adentro: si dos personas de la
-- comisión escanean el mismo QR a la vez, una sola gana y la otra ve
-- "ya_entregado". Ese es todo el anti-doble-entrega.
create function canjear_pin(p_token uuid)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
  v_ok boolean := false;
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;

  select id into v_id from insignias_ganadas where canje_token = p_token;
  if v_id is null then
    return jsonb_build_object('ok', false, 'motivo', 'inexistente');
  end if;

  update insignias_ganadas
  set canje_estado = 'entregado', canjeada_en = now(), canjeada_por = auth.uid()
  where id = v_id and canje_estado = 'pendiente';
  v_ok := found;

  if not v_ok then
    return ver_canje(p_token) || jsonb_build_object('ok', false, 'motivo', 'ya_entregado');
  end if;

  return ver_canje(p_token);
end $$;
