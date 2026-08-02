-- Ajuste del árbol de pruebas (BT-40).
--
-- `test-01` ya existía (creado desde el panel), inactivo y sin F propia, así
-- que la migración anterior —que solo inserta si falta— no lo tocó. Acá se le
-- ponen los valores que lo hacen útil para probar:
--   - F propia 0.4: con el déficit de un solo día seco ya pide agua, aunque
--     acabe de llover. Sin esto, después de una lluvia todos los árboles quedan
--     felices (el modelo funcionando bien) y no hay botón de riego que probar.
--   - sin coordenadas: el riego no exige proximidad, así se prueba desde casa.
--   - activo: para que aparezca en la lista.
--
-- ⚠️ Desactivarlo (activo = false) cuando no se esté probando: si no, encabeza
-- la lista de sedientos de la app como si fuera un árbol real.
update arboles set
  nombre = 'Árbol de pruebas',
  sector = 'Pruebas',
  frecuencia_dias_override = 0.4,
  lat = null,
  lng = null,
  activo = true
where codigo = 'test-01';
