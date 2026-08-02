-- Roles (BT-39): un solo admin hardcodeado (Pedro) + un nivel nuevo,
-- "entregador de pin", que el admin da de alta para la gente de la comisión.
--
-- Antes: ser admin era un flag en perfiles, seteado por migración. Ahora el
-- admin se reconoce por su mail, hardcodeado — nadie se autoasciende, ni por
-- accidente. El entregador SOLO puede validar y entregar pines (el /admin/canje
-- del evento): no toca árboles, config, ni crea otros entregadores.

-- ---------- admin = solo Pedro, por mail ----------
create or replace function es_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from auth.users
    where id = auth.uid() and lower(email) = 'josepedrodiaz@gmail.com'
  )
$$;

-- ---------- nuevo rol: entregador de pin ----------
alter table perfiles add column if not exists entregador boolean not null default false;

-- ¿Puede canjear? El admin o un entregador. Es el candado del validador.
create function puede_canjear() returns boolean
language sql stable security definer set search_path = public as $$
  select es_admin() or coalesce(
    (select p.entregador from perfiles p where p.id = auth.uid()), false)
$$;

-- ---------- cerrar el agujero: nadie se pone el rol solo ----------
-- El vecino puede editar su propio perfil (nombre). Sin esto, podría meter un
-- update/insert poniéndose entregador = true. Los roles solo cambian por las
-- RPC security definer de abajo, gateadas por es_admin().
create or replace function proteger_campos_perfil() returns trigger
language plpgsql as $$
begin
  if not es_admin() and current_setting('role', true) <> 'service_role' then
    new.es_admin := old.es_admin;
    new.puntos := old.puntos;
    new.entregador := old.entregador;
  end if;
  return new;
end $$;

drop policy perfil_propio_insert on perfiles;
create policy perfil_propio_insert on perfiles for insert
  with check (id = auth.uid() and es_admin = false and puntos = 0 and entregador = false);

-- ---------- el admin da de alta un entregador por mail ----------
-- La persona ya tiene que haber entrado a la app una vez (así existe su
-- cuenta). Devuelve el nombre para confirmar que agarraste a quien esperabas.
create function hacer_entregador(p_email text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
  v_nombre text;
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;
  select u.id into v_id from auth.users u where lower(u.email) = lower(trim(p_email));
  if v_id is null then
    return jsonb_build_object('ok', false, 'motivo', 'sin_cuenta');
  end if;
  update perfiles set entregador = true where id = v_id;
  if not found then
    return jsonb_build_object('ok', false, 'motivo', 'sin_perfil');
  end if;
  select nombre into v_nombre from perfiles where id = v_id;
  return jsonb_build_object('ok', true, 'nombre', v_nombre, 'email', lower(trim(p_email)));
end $$;

-- ---------- sacarle el rol a alguien ----------
create function quitar_entregador(p_perfil uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;
  update perfiles set entregador = false where id = p_perfil;
  return jsonb_build_object('ok', true);
end $$;

-- ---------- lista de entregadores (para el panel) ----------
create function listar_entregadores() returns jsonb
language plpgsql stable security definer set search_path = public as $$
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;
  return jsonb_build_object('ok', true, 'entregadores', coalesce((
    select jsonb_agg(jsonb_build_object('id', p.id, 'nombre', p.nombre, 'email', u.email)
             order by p.nombre)
    from perfiles p join auth.users u on u.id = p.id
    where p.entregador
  ), '[]'::jsonb));
end $$;

-- ---------- el validador ahora deja pasar a los entregadores ----------
-- Mismas funciones que en BT-21, con el candado cambiado de es_admin() a
-- puede_canjear(). canjeada_por sigue siendo auth.uid(): queda registrado qué
-- entregador entregó cada pin.
create or replace function ver_canje(p_token uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_fila record;
begin
  if not puede_canjear() then
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

create or replace function canjear_pin(p_token uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
  v_ok boolean := false;
begin
  if not puede_canjear() then
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
