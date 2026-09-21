-- El teléfono ve SUS riegos a un árbol sin leer dispositivo_id de la tabla.
create or replace function mis_riegos_arbol(p_dispositivo_id text, p_arbol_id uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(creado_en order by creado_en desc), '[]'::jsonb)
  from riegos where arbol_id = p_arbol_id and dispositivo_id = p_dispositivo_id;
$$;

-- Lo que este teléfono tiene sin reclamar (pantalla de crear cuenta).
create or replace function riegos_por_reclamar(p_dispositivo_id text)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object('riegos', count(*), 'puntos', coalesce(sum(puntos), 0))
  from riegos where dispositivo_id = p_dispositivo_id and perfil_id is null;
$$;

-- Cerrar la columna: los device id dejan de ser enumerables.
revoke select on riegos from anon, authenticated;
grant select (id, arbol_id, perfil_id, estado_al_regar, puntos, lat, lng, creado_en)
  on riegos to anon, authenticated;
