-- 1) gate: como VECINO (no admin), resolver debe rebotar
select set_config('request.jwt.claims',
  json_build_object('sub',(select id from auth.users where lower(email)='vecino@test.com'),
                    'role','authenticated')::text, true);
select resolver_reporte(
  (select id from reportes where estado='pendiente' order by creado_en desc limit 1), true) as intento_no_admin;