-- Revertir una entrega de pin (BT-39): el undo del evento.
-- Alguien va a marcar "entregado" por error el 21/09 — esto lo deshace sin
-- tocar la base a mano. SOLO el admin: el entregador entrega, no des-entrega
-- (si no, un error de dedo de un entregador podría "liberar" un pin ya dado).
-- La condición canje_estado = 'entregado' hace la reversión idempotente: si
-- ya está pendiente no hay nada que revertir y lo dice.
create function revertir_canje(p_token uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;

  update insignias_ganadas
  set canje_estado = 'pendiente', canjeada_en = null, canjeada_por = null
  where canje_token = p_token and canje_estado = 'entregado';

  if not found then
    return jsonb_build_object('ok', false, 'motivo', 'no_revertible');
  end if;

  -- Devuelve el canje ya revertido: el validador queda mostrando el pin
  -- listo para entregar de nuevo.
  return ver_canje(p_token);
end $$;
