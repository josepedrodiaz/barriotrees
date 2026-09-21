-- Reportes de árbol en peligro (BT): cerrar el ciclo que el esquema ya preveía.
--
-- El insert lo hace el vecino directo (policy `reportar`): queda 'pendiente',
-- 0 puntos, a su nombre. Los puntos NO se dan al reportar —así nadie farmea
-- reportes truchos— sino cuando el admin lo verifica. Ese otorgamiento (puntos
-- + insignia Centinela) toca perfiles e insignias_ganadas, que no tienen policy
-- de escritura: por eso vive acá, en un RPC security definer, como registrar_riego.
create or replace function resolver_reporte(p_reporte_id uuid, p_verificar boolean)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_reporte reportes%rowtype;
  v_puntos integer := (select (valor)::integer from config where clave = 'puntos_reporte_verificado');
  v_n integer := (select (valor)::integer from config where clave = 'centinela_n');
  v_total integer;
  v_verificados integer;
  v_insignia jsonb := 'null'::jsonb;
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;

  select * into v_reporte from reportes where id = p_reporte_id;
  if not found then
    return jsonb_build_object('ok', false, 'motivo', 'inexistente');
  end if;
  if v_reporte.estado <> 'pendiente' then
    return jsonb_build_object('ok', false, 'motivo', 'ya_resuelto');
  end if;

  -- Rechazado: se marca y listo, sin puntos.
  if not p_verificar then
    update reportes
      set estado = 'rechazado', resuelto_en = now(), resuelto_por = auth.uid()
    where id = p_reporte_id;
    return jsonb_build_object('ok', true, 'estado', 'rechazado');
  end if;

  -- Verificado: marca el reporte y le da los puntos al que avisó.
  update reportes
    set estado = 'verificado', resuelto_en = now(), resuelto_por = auth.uid(), puntos = v_puntos
  where id = p_reporte_id;

  update perfiles set puntos = puntos + v_puntos where id = v_reporte.perfil_id
  returning puntos into v_total;

  -- Insignia Centinela: N reportes verificados (config centinela_n).
  select count(*) into v_verificados from reportes
  where perfil_id = v_reporte.perfil_id and estado = 'verificado';

  if v_verificados >= v_n
     and not exists (select 1 from insignias_ganadas g
                     where g.perfil_id = v_reporte.perfil_id and g.insignia_id = 'centinela') then
    insert into insignias_ganadas (perfil_id, insignia_id) values (v_reporte.perfil_id, 'centinela');
    select jsonb_build_object('id', i.id, 'nombre', i.nombre, 'copy', i.copy_desbloqueo)
    into v_insignia from insignias i where i.id = 'centinela';
  end if;

  return jsonb_build_object(
    'ok', true,
    'estado', 'verificado',
    'puntos', v_puntos,
    'total_puntos', v_total,
    'insignia', v_insignia
  );
end $$;
