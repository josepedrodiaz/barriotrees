-- Reseteo total del juego (BT-40): la opción nuclear del super admin.
--
-- limpiar_pruebas() es quirúrgico: borra solo los árboles test-* y preserva las
-- insignias YA ENTREGADAS (ese pin está en la mano de alguien). Pero durante las
-- pruebas se entregan pines de mentira, así que "no tocar los entregados" deja
-- basura. Esto borra TODO el estado de juego y deja la base como el día 0:
--   - todos los riegos, de árboles reales y de prueba
--   - todas las insignias ganadas, pendientes Y entregadas
--   - todos los puntos a cero
--   - los árboles de prueba (test-*)
--
-- NO toca: las cuentas de los vecinos (perfiles), las especies, la config, los
-- roles de entregador, ni los árboles REALES de la plaza (jaca-*). Es "borrar
-- todo lo jugado", no "borrar el mundo".
--
-- Solo es_admin (que está hardcodeado a un único mail): el super admin y nadie
-- más. Sin vuelta atrás — la UI pide confirmación tipeada.
create function resetear_juego() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_riegos integer;
  v_insignias integer;
  v_arboles integer;
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;

  -- Orden por las FK (ninguna cascadea entre estas tablas).
  delete from insignias_ganadas;           -- incluye las entregadas, a propósito
  get diagnostics v_insignias = row_count;

  delete from reportes;
  delete from riegos;
  get diagnostics v_riegos = row_count;

  delete from arboles where codigo like 'test-%';
  get diagnostics v_arboles = row_count;

  update perfiles set puntos = 0 where puntos <> 0;

  return jsonb_build_object(
    'ok', true,
    'riegos_borrados', v_riegos,
    'insignias_borradas', v_insignias,
    'arboles_prueba_borrados', v_arboles
  );
end $$;
