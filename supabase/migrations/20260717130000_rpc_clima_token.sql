-- Solo el admin puede ver el clima_token (para pegarlo en el secreto de GitHub
-- Actions). El token vive en la tabla `secretos`, que no se lee por la API;
-- esta RPC security definer es la única puerta, y solo si sos admin.
create function obtener_clima_token()
returns jsonb
language plpgsql stable security definer set search_path = public as $$
begin
  if not es_admin() then
    return jsonb_build_object('ok', false, 'motivo', 'no_admin');
  end if;
  return jsonb_build_object(
    'ok', true,
    'token', (select valor from secretos where clave = 'clima_token')
  );
end $$;
