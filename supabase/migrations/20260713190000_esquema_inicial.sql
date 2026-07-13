-- Esquema inicial de Árboles Gigantes.
-- Principio (docs/arquitectura.md): las tablas guardan HECHOS; las reglas y
-- números del juego viven en `config` y en el catálogo `insignias`, editables
-- sin migración. Escrituras de juego solo vía RPC (llegan en BT-11); acá solo
-- lectura pública + ABM de admin.

-- ---------- enums ----------
create type estado_arbol as enum ('feliz', 'bien', 'sediento', 'muy_sediento');
create type tipo_insignia as enum ('escalera', 'merito');
create type estado_canje as enum ('pendiente', 'entregado');
create type tipo_reporte as enum ('hormigas', 'plaga', 'rama_rota', 'vandalismo', 'otro');
create type estado_reporte as enum ('pendiente', 'verificado', 'rechazado');

-- ---------- config del juego (clave/valor, editable por admin) ----------
create table config (
  clave text primary key,
  valor jsonb not null,
  descripcion text
);

-- ---------- especies ----------
create table especies (
  id uuid primary key default gen_random_uuid(),
  ref_plano text,                      -- A1..A15 del plano municipal; null si no figura
  nombre_cientifico text not null,
  nombre_comun text not null,
  frecuencia_dias numeric not null,    -- F: días entre riegos (árbol joven, verano)
  en_programa boolean not null default true,  -- false = preexistencias (solo emergencia)
  creado_en timestamptz not null default now()
);

-- ---------- arboles ----------
create table arboles (
  id uuid primary key default gen_random_uuid(),
  codigo text not null unique,         -- slug corto para URL/QR: 'jaca-01'
  especie_id uuid not null references especies (id),
  nombre text,                         -- se desbloquea por votación (premio), null hasta entonces
  fecha_plantacion date,
  sector text,                         -- 'galeria-central', 'sector-a', 'sector-b', 'perimetro'
  lat double precision,
  lng double precision,
  altura_cm integer,
  notas text,
  frecuencia_dias_override numeric,    -- si un árbol puntual necesita otra F
  activo boolean not null default true,
  creado_en timestamptz not null default now()
);

-- ---------- perfiles (1:1 con auth.users) ----------
create table perfiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nombre text not null,
  es_admin boolean not null default false,
  puntos integer not null default 0,   -- acumulado; lo mantiene la RPC registrar_riego
  creado_en timestamptz not null default now()
);

-- ---------- riegos (el hecho central del juego) ----------
create table riegos (
  id uuid primary key default gen_random_uuid(),
  arbol_id uuid not null references arboles (id),
  perfil_id uuid references perfiles (id),
  dispositivo_id text,                 -- riego anónimo: se reclama al crear cuenta
  estado_al_regar estado_arbol not null,
  puntos integer not null default 0,
  lat double precision,
  lng double precision,
  creado_en timestamptz not null default now(),
  constraint riego_con_autor check (perfil_id is not null or dispositivo_id is not null)
);
create index riegos_arbol_fecha on riegos (arbol_id, creado_en desc);
create index riegos_perfil on riegos (perfil_id, creado_en desc);
create index riegos_dispositivo on riegos (dispositivo_id) where dispositivo_id is not null;

-- ---------- insignias (catálogo: escalera + mérito) ----------
create table insignias (
  id text primary key,                 -- slug: 'primer-riego', 'gigante-del-oeste'
  tipo tipo_insignia not null,
  orden integer,                       -- posición en la escalera (1..7); null para mérito
  nombre text not null,
  umbral_puntos integer,               -- escalera: puntos acumulados que la desbloquean
  criterio jsonb,                      -- mérito: {"evento": "rescate", "n": 5}
  copy_desbloqueo text not null,       -- el texto motivador que se muestra al ganarla
  es_pin boolean not null default true,
  activa boolean not null default true
);

-- ---------- insignias ganadas + canje del pin físico ----------
create table insignias_ganadas (
  id uuid primary key default gen_random_uuid(),
  perfil_id uuid not null references perfiles (id) on delete cascade,
  insignia_id text not null references insignias (id),
  ganada_en timestamptz not null default now(),
  canje_estado estado_canje not null default 'pendiente',
  canje_token uuid not null unique default gen_random_uuid(),  -- el QR de canje
  canjeada_en timestamptz,
  canjeada_por uuid references perfiles (id),
  unique (perfil_id, insignia_id)
);

-- ---------- reportes de peligro (hormigas, plagas...; v1.1 pero el esquema ya lo contempla) ----------
create table reportes (
  id uuid primary key default gen_random_uuid(),
  arbol_id uuid not null references arboles (id),
  perfil_id uuid not null references perfiles (id),
  tipo tipo_reporte not null,
  descripcion text,
  estado estado_reporte not null default 'pendiente',
  puntos integer not null default 0,   -- se otorgan al verificarse
  creado_en timestamptz not null default now(),
  resuelto_en timestamptz,
  resuelto_por uuid references perfiles (id)
);

-- ---------- estado actual de cada árbol (derivado, no guardado) ----------
create view v_arboles_estado as
select
  a.*,
  e.nombre_comun as especie_nombre,
  e.nombre_cientifico as especie_cientifico,
  coalesce(a.frecuencia_dias_override, e.frecuencia_dias)
    * coalesce((select (valor)::numeric from config where clave = 'multiplicador_estacional'), 1)
    as f_efectiva,
  ur.ultimo_riego,
  extract(epoch from (now() - ur.ultimo_riego)) / 86400.0 as dias_sin_riego,
  case
    when ur.ultimo_riego is null then 'muy_sediento'::estado_arbol
    else (
      with f as (
        select coalesce(a.frecuencia_dias_override, e.frecuencia_dias)
          * coalesce((select (valor)::numeric from config where clave = 'multiplicador_estacional'), 1) as v
      )
      select case
        when extract(epoch from (now() - ur.ultimo_riego)) / 86400.0
          <= f.v * coalesce((select (valor)::numeric from config where clave = 'banda_feliz'), 0.5) then 'feliz'
        when extract(epoch from (now() - ur.ultimo_riego)) / 86400.0
          <= f.v * coalesce((select (valor)::numeric from config where clave = 'banda_bien'), 1) then 'bien'
        when extract(epoch from (now() - ur.ultimo_riego)) / 86400.0
          <= f.v * coalesce((select (valor)::numeric from config where clave = 'banda_sediento'), 2) then 'sediento'
        else 'muy_sediento'
      end::estado_arbol from f
    )
  end as estado
from arboles a
join especies e on e.id = a.especie_id
left join lateral (
  select max(r.creado_en) as ultimo_riego from riegos r where r.arbol_id = a.id
) ur on true
where a.activo;

-- ---------- RLS ----------
alter table config enable row level security;
alter table especies enable row level security;
alter table arboles enable row level security;
alter table perfiles enable row level security;
alter table riegos enable row level security;
alter table insignias enable row level security;
alter table insignias_ganadas enable row level security;
alter table reportes enable row level security;

-- helper: ¿el usuario logueado es admin?
create function es_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select coalesce((select p.es_admin from perfiles p where p.id = auth.uid()), false) $$;

-- Lectura pública (la app es abierta: cualquiera ve árboles, riegos, ranking).
create policy lectura_publica on config for select using (true);
create policy lectura_publica on especies for select using (true);
create policy lectura_publica on arboles for select using (true);
create policy lectura_publica on perfiles for select using (true);
create policy lectura_publica on riegos for select using (true);
create policy lectura_publica on insignias for select using (true);
create policy lectura_publica on insignias_ganadas for select using (true);
create policy lectura_publica on reportes for select using (true);

-- Perfil propio: crearlo y editar el nombre. (puntos/es_admin los protege la
-- ausencia de policy de update sobre esas filas ajenas + el trigger de abajo.)
create policy perfil_propio_insert on perfiles for insert
  with check (id = auth.uid() and es_admin = false and puntos = 0);
create policy perfil_propio_update on perfiles for update
  using (id = auth.uid());

-- Nadie se auto-asciende ni se auto-puntúa: en updates propios, es_admin y
-- puntos solo pueden cambiar desde funciones security definer (RPCs del juego).
create function proteger_campos_perfil() returns trigger
language plpgsql as $$
begin
  if not es_admin() and current_setting('role', true) <> 'service_role' then
    new.es_admin := old.es_admin;
    new.puntos := old.puntos;
  end if;
  return new;
end $$;
create trigger perfiles_proteger before update on perfiles
  for each row execute function proteger_campos_perfil();

-- ABM de admin (especies, árboles, config, catálogo, reportes y canjes).
create policy admin_todo on config for all using (es_admin()) with check (es_admin());
create policy admin_todo on especies for all using (es_admin()) with check (es_admin());
create policy admin_todo on arboles for all using (es_admin()) with check (es_admin());
create policy admin_todo on insignias for all using (es_admin()) with check (es_admin());
create policy admin_update on insignias_ganadas for update using (es_admin()) with check (es_admin());
create policy admin_update on reportes for update using (es_admin()) with check (es_admin());

-- Reportar un peligro: cualquier vecino logueado, sobre su propio nombre.
create policy reportar on reportes for insert
  with check (perfil_id = auth.uid() and estado = 'pendiente' and puntos = 0);

-- Riegos e insignias_ganadas NO tienen policies de escritura: se insertan
-- únicamente vía RPC security definer (BT-11). Ese es el corazón del anti-trampa.

-- ---------- seeds: config del juego (docs/reglas-del-juego.md) ----------
insert into config (clave, valor, descripcion) values
  ('banda_feliz',                 '0.5',  'estado feliz: días sin riego <= banda * F'),
  ('banda_bien',                  '1',    'estado bien: días sin riego <= banda * F'),
  ('banda_sediento',              '2',    'estado sediento: días sin riego <= banda * F (más allá: muy sediento)'),
  ('multiplicador_estacional',    '1',    'agranda F fuera de temporada (x2 otoño, x3 invierno)'),
  ('puntos_riego',                '{"feliz": 1, "bien": 5, "sediento": 15, "muy_sediento": 25}', 'puntos por riego según estado del árbol'),
  ('puntos_reporte_verificado',   '15',   'puntos al verificarse un reporte de peligro'),
  ('cooldown_arbol_horas',        '12',   'un árbol no suma dos riegos dentro de esta ventana'),
  ('cooldown_vecino_arbol_horas', '20',   'un vecino no repite el mismo árbol dentro de esta ventana'),
  ('duracion_riego_segundos',     '20',   'duración mínima de la pantalla Regando…'),
  ('radio_proximidad_metros',     '50',   'distancia máxima al árbol para validar el riego'),
  ('rescatista_n',                '5',    'rescates (riegos a muy sediento) para la insignia Rescatista'),
  ('madrugador_n',                '10',   'riegos antes de la hora límite para Madrugador'),
  ('madrugador_hora_limite',      '9',    'hora local límite para que un riego cuente como madrugador'),
  ('centinela_n',                 '3',    'reportes verificados para la insignia Centinela');

-- ---------- seeds: especies (docs/especies-umbrales.md; F árbol joven, verano) ----------
insert into especies (ref_plano, nombre_cientifico, nombre_comun, frecuencia_dias, en_programa) values
  (null, 'Jacaranda mimosifolia',            'Jacarandá',            2, true),
  ('A5', 'Paulownia tomentosa',              'Kiri',                 2, true),
  ('A6', 'Liquidambar styraciflua',          'Liquidámbar',          2, true),
  ('A3', 'Fraxinus pennsylvanica',           'Fresno rojo',          2, true),
  ('A11','Citrus reticulata',                'Mandarino',            2, true),
  ('A12','Citrus × sinensis',                'Naranjo',              2, true),
  ('A13','Citrus × paradisi',                'Pomelo',               2, true),
  ('A2', 'Tabebuia impetiginosa',            'Lapacho rosado',       3, true),
  ('A4', 'Tipuana tipu',                     'Tipa',                 3, true),
  ('A7', 'Bauhinia forficata',               'Pezuña de vaca',       3, true),
  ('A8', 'Bauhinia variegata',               'Pezuña de vaca rosa',  3, true),
  ('A10','Prunus cerasifera Atropurpurea',   'Ciruelo de jardín',    3, true),
  ('A14','Prunus armeniaca',                 'Damasco',              3, true),
  ('A15','Ginkgo biloba',                    'Ginkgo',               3, true),
  ('A9', 'Washingtonia filifera',            'Palmera washingtonia', 4, true),
  ('A1', 'Preexistencia',                    'Árbol establecido',    7, false);

-- ---------- seeds: insignias (escalera de 7 + méritos; docs/reglas-del-juego.md) ----------
insert into insignias (id, tipo, orden, nombre, umbral_puntos, criterio, copy_desbloqueo) values
  ('primer-riego',      'escalera', 1, 'Primer Riego',      1,     null, 'Todo gigante empezó con un balde de agua. Este fue el tuyo.'),
  ('aprendiz',          'escalera', 2, 'Aprendiz',          100,   null, 'Ya no fue casualidad: volviste. Así se empieza a cuidar.'),
  ('cuidador',          'escalera', 3, 'Cuidador',          300,   null, 'La plaza ya te conoce. Y vos ya la conocés a ella.'),
  ('gran-cuidador',     'escalera', 4, 'Gran Cuidador',     800,   null, 'Constancia: la palabra menos glamorosa y más importante del cuidado.'),
  ('raiz-del-barrio',   'escalera', 5, 'Raíz del Barrio',   2000,  null, 'Hay vecinos que pasan. Y hay vecinos que echan raíces.'),
  ('alma-de-la-plaza',  'escalera', 6, 'Alma de la Plaza',  4500,  null, 'Cuando la plaza está mejor, es en parte por vos. Literalmente.'),
  ('gigante-del-oeste', 'escalera', 7, 'Gigante del Oeste', 10000, null, 'Los árboles todavía son chicos. El gigante, por ahora, sos vos.'),
  ('rescatista',        'merito', null, 'Rescatista', null, '{"evento": "rescate", "config_n": "rescatista_n"}',            'Estaban al límite y llegaste vos. Los rescates no se olvidan.'),
  ('madrugador',        'merito', null, 'Madrugador', null, '{"evento": "madrugada", "config_n": "madrugador_n"}',          'El mejor momento para regar es cuando casi nadie está despierto. Vos estabas.'),
  ('centinela',         'merito', null, 'Centinela',  null, '{"evento": "reporte_verificado", "config_n": "centinela_n"}',  'Ver el problema antes de que sea grave también es cuidar. Ojos así valen oro.');
