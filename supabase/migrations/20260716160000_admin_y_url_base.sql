-- Panel de admin (BT-19).
--
-- Las policies de admin ya existen desde BT-10 (admin_todo sobre arboles,
-- especies, config e insignias): lo único que faltaba era que alguien fuera
-- admin. No hay pantalla para nombrar admins a propósito — se hace por
-- migración, que queda versionada y a la vista de todos.
update perfiles
set es_admin = true
where id = (select id from auth.users where email = 'josepedrodiaz@gmail.com');

-- La URL a la que apuntan los QR de las chapitas. Vive en config y no en el
-- código porque el dominio todavía puede cambiar (hoy es el subdominio de
-- Vercel), y una chapita mal impresa es una chapita muerta en la plaza.
-- Al cambiarla acá, los QR que genere el admin salen apuntando al dominio
-- nuevo sin tocar una línea.
insert into config (clave, valor, descripcion) values
  ('url_base', '"https://arboles-gigantes.vercel.app"',
   'dominio al que apuntan los QR de los arboles; cambiar antes de imprimir chapitas nuevas');
