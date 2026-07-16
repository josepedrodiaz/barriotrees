-- Centinela se gana reportando peligros (hormigas, plagas) verificados por el
-- admin, y ese circuito es v1.1: hoy no hay dónde reportar. Mostrarla en la
-- app sería prometer algo que no se puede hacer.
--
-- Se apaga en el catálogo, que es lo que manda: otorgar_insignias solo mira
-- las activas, y la pantalla solo lista las activas. Cuando exista el reporte
-- de peligros, esto se prende con un update y nada más.
update insignias set activa = false where id = 'centinela';
