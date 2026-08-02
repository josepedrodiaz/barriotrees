-- Alta de entregador por lista, no por mail (BT-39).
-- El mail no sirve en la práctica: nadie se acuerda con qué se registró, y
-- auth.users no es visible. Como perfiles es de lectura pública (nombre), el
-- admin elige de la lista de registrados y marca el rol con esta RPC por id.
create function poner_entregador(p_perfil uuid, p_valor boolean) returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;
  update perfiles set entregador = coalesce(p_valor, false) where id = p_perfil;
  if not found then
    return jsonb_build_object('ok', false, 'motivo', 'inexistente');
  end if;
  return jsonb_build_object('ok', true);
end $$;
