-- Grant explícito de lectura sobre las vistas derivadas. En prod ya estaba
-- (default de Supabase al crearse), pero nunca quedó versionado, así que un
-- `db reset` desde cero dejaba a anon sin poder leerlas: home en 0 y ficha de
-- árbol en 404. Lo fijamos para que local == prod y la base sea reproducible.
grant select on v_arboles_estado to anon, authenticated;
grant select on v_ranking to anon, authenticated;
