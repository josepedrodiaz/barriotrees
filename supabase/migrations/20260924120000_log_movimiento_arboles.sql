-- Historial de movimientos de árboles: quién, cuándo y de dónde a dónde.
-- Se llena solo via trigger en cada UPDATE de lat/lng en arboles.
create table arboles_movimientos (
  id uuid primary key default gen_random_uuid(),
  arbol_id uuid not null references arboles(id) on delete cascade,
  lat_anterior double precision,
  lng_anterior double precision,
  lat_nuevo double precision,
  lng_nuevo double precision,
  movido_por uuid references perfiles(id),
  movido_en timestamptz not null default now()
);

alter table arboles_movimientos enable row level security;

-- Nadie escribe directo (solo el trigger, que es security definer). Lectura: solo admin.
create policy admin_lee on arboles_movimientos for select using (es_admin());

create function registrar_movimiento_arbol() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.lat is distinct from old.lat or new.lng is distinct from old.lng then
    insert into arboles_movimientos (arbol_id, lat_anterior, lng_anterior, lat_nuevo, lng_nuevo, movido_por)
    values (new.id, old.lat, old.lng, new.lat, new.lng, auth.uid());
  end if;
  return new;
end $$;

create trigger arboles_registrar_movimiento after update on arboles
  for each row execute function registrar_movimiento_arbol();
