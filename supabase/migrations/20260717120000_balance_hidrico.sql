-- Balance hídrico: el clima real ajusta la sed de los árboles (BT-33).
-- Reemplaza el "reloj tonto" (días sin riego) por el déficit de agua real:
-- cada día el suelo pierde por evapotranspiración (ET0) y gana por lluvia.
-- Datos de Open-Meteo (ver el ticket BT-33). El modelo viejo es este mismo con
-- el supuesto "cada día evapora ET0_ref y no llueve", así que degrada solo si
-- falta el dato.

-- ---------- clima de la plaza, un registro por día ----------
create table clima_diario (
  fecha date primary key,
  lluvia_mm numeric not null default 0,
  et0_mm numeric not null default 0, -- evapotranspiración de referencia (FAO)
  temp_max numeric,                  -- para olas de calor (v1.1 de gamificación)
  creado_en timestamptz not null default now()
);
alter table clima_diario enable row level security;
create policy lectura_publica on clima_diario for select using (true);
-- La escritura entra solo por la RPC token-gated (la tarea diaria); nadie más.

-- ---------- secretos que NO pueden ser públicos ----------
-- config es de lectura pública, así que un token ahí sería visible por
-- cualquiera (lección del canje_token). Los secretos viven acá, en una tabla
-- con RLS y sin ninguna policy: nadie los lee por la API; solo las funciones
-- security definer (que saltean RLS) los ven.
create table secretos (
  clave text primary key,
  valor text not null
);
alter table secretos enable row level security;

insert into secretos (clave, valor) values ('clima_token', gen_random_uuid()::text);

-- ---------- config del balance (editable por admin) ----------
insert into config (clave, valor, descripcion) values
  ('et0_referencia_mm', '4.5',
   'ET0 típica de verano en La Plata (mm/día). Convierte la F de la especie (en días) a déficit en mm, y es el fallback cuando falta el clima de un día.'),
  ('ola_calor_temp', '32',
   'temperatura máxima (°C) desde la cual el día cuenta como ola de calor (para puntos dobles, v1.1)');

-- ---------- el déficit de agua acumulado de un árbol (mm) ----------
-- Desde el día siguiente al último riego (o desde la plantación / ventana de
-- 14 días si nunca se regó), suma la ET0 y resta la lluvia día por día, con
-- tope en 0: una lluvia fuerte no banca crédito infinito (el suelo se satura).
-- Los días sin dato de clima usan ET0_ref y lluvia 0 (reproducen el reloj).
create function f_deficit_mm(p_arbol uuid)
returns numeric
language plpgsql stable security definer set search_path = public as $$
declare
  v_ultimo date := (select max(creado_en)::date from riegos where arbol_id = p_arbol);
  v_et0ref numeric := coalesce((select (valor)::numeric from config where clave = 'et0_referencia_mm'), 4.5);
  v_desde date;
  v_saldo numeric := 0;
  r record;
begin
  if v_ultimo is not null then
    v_desde := v_ultimo + 1; -- el día del riego el árbol quedó lleno
  else
    v_desde := greatest(
      coalesce((select fecha_plantacion from arboles where id = p_arbol), current_date - 14),
      current_date - 30 -- techo: más atrás el déficit ya estaría saturado
    );
  end if;

  for r in
    select coalesce(c.et0_mm, v_et0ref) as et0, coalesce(c.lluvia_mm, 0) as lluvia
    from generate_series(v_desde::timestamp, current_date::timestamp, interval '1 day') d
    left join clima_diario c on c.fecha = d::date
    order by d
  loop
    v_saldo := greatest(0, v_saldo + r.et0 - r.lluvia);
  end loop;

  return v_saldo;
end $$;

-- ---------- estado del árbol, ahora por balance ----------
-- Mismas bandas de siempre, pero medidas en "días equivalentes de sed"
-- (déficit / ET0_ref) en vez de días de calendario.
create or replace function f_estado_arbol(p_arbol_id uuid)
returns table (estado estado_arbol, dias_sin_riego numeric, f_efectiva numeric)
language sql stable security definer set search_path = public as $$
  with datos as (
    select
      coalesce(a.frecuencia_dias_override, e.frecuencia_dias)
        * coalesce((select (valor)::numeric from config where clave = 'multiplicador_estacional'), 1) as f,
      (select max(r.creado_en) from riegos r where r.arbol_id = a.id) as ultimo,
      f_deficit_mm(a.id) as deficit,
      coalesce((select (valor)::numeric from config where clave = 'et0_referencia_mm'), 4.5) as et0ref
    from arboles a join especies e on e.id = a.especie_id
    where a.id = p_arbol_id
  )
  select
    case
      when (deficit / et0ref) <= f * coalesce((select (valor)::numeric from config where clave = 'banda_feliz'), 0.5) then 'feliz'
      when (deficit / et0ref) <= f * coalesce((select (valor)::numeric from config where clave = 'banda_bien'), 1) then 'bien'
      when (deficit / et0ref) <= f * coalesce((select (valor)::numeric from config where clave = 'banda_sediento'), 2) then 'sediento'
      else 'muy_sediento'
    end::estado_arbol,
    extract(epoch from (now() - ultimo)) / 86400.0,
    f
  from datos;
$$;

-- ---------- la vista, ahora sin duplicar la lógica ----------
-- Antes repetía el cálculo de estado inline; ahora delega en f_estado_arbol y
-- expone el déficit y la lluvia reciente para que la UI pueda decir
-- "hoy llovió, no hace falta regar".
drop view v_arboles_estado;
create view v_arboles_estado as
select
  a.*,
  e.nombre_comun as especie_nombre,
  e.nombre_cientifico as especie_cientifico,
  st.f_efectiva,
  st.dias_sin_riego,
  st.estado,
  round(f_deficit_mm(a.id), 1) as deficit_mm,
  coalesce((select sum(c.lluvia_mm) from clima_diario c where c.fecha > current_date - 3), 0) as lluvia_3d
from arboles a
join especies e on e.id = a.especie_id
cross join lateral f_estado_arbol(a.id) st
where a.activo;

-- ---------- registrar el clima del día (la tarea diaria) ----------
-- Token-gated: solo quien tiene el clima_token (un secret en GitHub Actions)
-- puede escribir. Idempotente por fecha (upsert): re-correr el día no duplica.
create function registrar_clima(
  p_token text,
  p_fecha date,
  p_lluvia numeric,
  p_et0 numeric,
  p_temp numeric default null
) returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  if p_token is null or p_token <> (select valor from secretos where clave = 'clima_token') then
    return jsonb_build_object('ok', false, 'motivo', 'no_autorizado');
  end if;

  insert into clima_diario (fecha, lluvia_mm, et0_mm, temp_max)
  values (p_fecha, coalesce(p_lluvia, 0), coalesce(p_et0, 0), p_temp)
  on conflict (fecha) do update
    set lluvia_mm = excluded.lluvia_mm,
        et0_mm = excluded.et0_mm,
        temp_max = excluded.temp_max,
        creado_en = now();

  return jsonb_build_object('ok', true, 'fecha', p_fecha);
end $$;
