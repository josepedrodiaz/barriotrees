-- Árbol de pruebas (BT-40): para ensayar el circuito completo sin ir a la plaza
-- y sin depender del clima.
--
-- El problema: después de una lluvia buena TODOS los árboles quedan felices —
-- que es el modelo funcionando bien— y sin sed no hay botón de riego, así que
-- no se puede probar el circuito. La palanca correcta ya existía en el esquema:
-- `frecuencia_dias_override`, una F propia del árbol. Con F=0.4 alcanza el
-- déficit de un solo día seco para que pida agua, llueva o no.
--
-- Sin coordenadas a propósito: sin lat/lng el riego no exige proximidad
-- (ver registrar_riego), así que se puede probar desde casa.
--
-- ⚠️ Es un árbol de mentira: desactivarlo (activo = false) cuando no se esté
-- probando, para que no aparezca primero en la lista de sedientos de la app.
insert into arboles (codigo, especie_id, nombre, sector, frecuencia_dias_override, activo)
select
  'test-01',
  (select id from especies where nombre_comun = 'Jacarandá'),
  'Árbol de pruebas',
  'Pruebas',
  0.4,
  true
where not exists (select 1 from arboles where codigo = 'test-01');
