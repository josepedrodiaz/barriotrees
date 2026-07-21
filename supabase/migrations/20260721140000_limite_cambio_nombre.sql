-- Límite al cambio de nombre (BT-35): 2 cambios en total y sin duplicados.
--
-- El nombre es la identidad pública en el ranking. Cambiarlo infinitas veces
-- permite despistar ("¿quién era el que ayer se llamaba Marta?") y pisar la
-- identidad de otro. Dos cambios alcanzan: uno para sacarse el prefijo del
-- mail y otro para arrepentirse. La UI avisa en el segundo que es el último.

alter table perfiles add column cambios_nombre int not null default 0;

-- Sin índice único sobre nombre: los perfiles existentes pueden traer
-- duplicados (el default sale del mail) y la migración no puede fallar por
-- eso. El chequeo vive en la RPC — única puerta de escritura del nombre
-- (perfiles no tiene policy de escritura), así que no hay otra vía que evadir.
create or replace function actualizar_mi_nombre(p_nombre text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_perfil uuid := auth.uid();
  v_limpio text := trim(regexp_replace(coalesce(p_nombre, ''), '\s+', ' ', 'g'));
  v_actual text;
  v_cambios int;
begin
  if v_perfil is null then
    return jsonb_build_object('ok', false, 'motivo', 'sin_sesion');
  end if;
  if length(v_limpio) < 2 then
    return jsonb_build_object('ok', false, 'motivo', 'muy_corto');
  end if;
  if length(v_limpio) > 24 then
    return jsonb_build_object('ok', false, 'motivo', 'muy_largo');
  end if;

  select nombre, cambios_nombre into v_actual, v_cambios
    from perfiles where id = v_perfil for update;

  -- Guardar el mismo nombre no gasta un cambio.
  if v_limpio = v_actual then
    return jsonb_build_object('ok', true, 'nombre', v_limpio, 'restantes', 2 - v_cambios);
  end if;

  if v_cambios >= 2 then
    return jsonb_build_object('ok', false, 'motivo', 'sin_cambios');
  end if;

  if exists (
    select 1 from perfiles
    where lower(nombre) = lower(v_limpio) and id <> v_perfil
  ) then
    return jsonb_build_object('ok', false, 'motivo', 'duplicado');
  end if;

  update perfiles
    set nombre = v_limpio, cambios_nombre = cambios_nombre + 1
    where id = v_perfil;
  return jsonb_build_object('ok', true, 'nombre', v_limpio, 'restantes', 1 - v_cambios);
end $$;
