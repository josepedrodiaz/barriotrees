-- Insignia Sereno: la franja del atardecer (pedido de Pedro, jul 2026).
-- Espejo de Madrugador: regar después de que baja el sol también es riego de
-- calidad (sin evaporación) y es la franja en la que la plaza más se mueve
-- (la vuelta del trabajo y de la escuela).

insert into config (clave, valor, descripcion) values
  ('sereno_n',           '10', 'riegos después de la hora de inicio para la insignia Sereno'),
  ('sereno_hora_inicio', '19', 'hora local desde la que un riego cuenta como sereno');

insert into insignias (id, tipo, orden, nombre, umbral_puntos, criterio, copy_desbloqueo) values
  ('sereno', 'merito', null, 'Sereno', null,
   '{"evento": "atardecer", "config_n": "sereno_n"}',
   'Cuando baja el sol, la plaza revive y el agua rinde. Vos ya estabas ahí, balde en mano.');
