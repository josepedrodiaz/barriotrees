-- El `revoke select (canje_token)` de la migración anterior no hizo nada: en
-- Postgres no se le puede restar una columna a un permiso dado sobre la tabla
-- entera, y Supabase otorga select sobre toda la tabla a anon/authenticated.
-- Verificado: después de aquel revoke, el token se seguía leyendo.
--
-- La forma que sí funciona: sacar el permiso de tabla y darlo de nuevo, pero
-- solo sobre las columnas que pueden ser públicas. El token queda fuera y solo
-- se llega a él por las RPC (el vecino ve el suyo, el admin valida).
revoke select on insignias_ganadas from anon, authenticated;

grant select (id, perfil_id, insignia_id, ganada_en, canje_estado, canjeada_en, canjeada_por)
  on insignias_ganadas to anon, authenticated;
