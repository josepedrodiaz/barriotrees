-- El árbol de pruebas estaba cargado como Preexistencia (BT-40).
--
-- Las preexistencias tienen en_programa = false y la pantalla inicial las
-- filtra del ranking de sedientos (BT-37), así que test-01 no aparecía en la
-- lista: solo se llegaba por URL. Para probar el circuito como lo vive un
-- vecino —abrir la app y ver el árbol sediento arriba— tiene que ser una
-- especie del programa.
update arboles
set especie_id = (select id from especies where nombre_comun = 'Jacarandá')
where codigo = 'test-01';
