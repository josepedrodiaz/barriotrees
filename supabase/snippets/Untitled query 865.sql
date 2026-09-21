select set_config('request.jwt.claims',
  json_build_object(
    'sub', (select id from auth.users where lower(email)='josepedrodiaz@gmail.com'),
    'role','authenticated')::text, true);

select resolver_reporte(
  (select id from reportes where estado='pendiente' order by creado_en desc limit 1),
  true) as resultado;

select nombre, puntos from perfiles
where id = (select id from auth.users where lower(email)='vecino@test.com');