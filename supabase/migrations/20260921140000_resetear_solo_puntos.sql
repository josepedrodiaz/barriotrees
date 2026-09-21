-- resetear_juego ahora resetea el MARCADOR: puntos e insignias (BT).
--
-- Antes era la "opción nuclear": borraba también riegos y reportes, o sea el
-- historial real de lo que la plaza regó y reportó. Eso no tiene sentido: el
-- historial es el valor del proyecto, no basura de prueba. Para limpiar datos
-- de prueba ya está limpiar_pruebas() (quirúrgico, solo test-*).
--
-- Ahora esto resetea solo el juego: los puntos a cero y las insignias borradas
-- (van de la mano del puntaje, incluidas las ya entregadas). Riegos, reportes,
-- árboles y cuentas quedan intactos.
create or replace function resetear_juego() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_insignias integer;
  v_puntos integer;
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;

  delete from insignias_ganadas;           -- incluye las entregadas: son el marcador
  get diagnostics v_insignias = row_count;

  update perfiles set puntos = 0 where puntos <> 0;
  get diagnostics v_puntos = row_count;

  return jsonb_build_object(
    'ok', true,
    'insignias_borradas', v_insignias,
    'perfiles_resetados', v_puntos
  );
end $$;
