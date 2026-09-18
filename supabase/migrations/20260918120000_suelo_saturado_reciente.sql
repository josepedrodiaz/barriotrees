-- f_suelo_saturado se quedaba pegada al último valor de humedad NO-NULL de
-- CUALQUIER fecha. Cuando el cron dejó de escribir humedad (del 3/09 en
-- adelante, porque el clima.yml de prod todavía no mandaba p_humedad), la
-- función siguió leyendo ese 0.45 viejo y frenó el riego con la plaza en
-- déficit severo — justo al revés de lo que debía.
--
-- Su propio comentario ya decía "si falta el dato, no frenamos": esto lo cumple
-- de verdad. La humedad de suelo es un valor instantáneo que el cron escribe en
-- la fila de HOY; solo tiene sentido si es fresca. Exigimos que sea de hoy o
-- ayer (margen por si un ciclo del cron falla). Sin dato reciente => no
-- saturado, y el riego se habilita en vez de trabarse con un dato rancio.
create or replace function f_suelo_saturado()
returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(
    (select c.humedad_suelo from clima_diario c
       where c.humedad_suelo is not null
         and c.fecha >= current_date - 1
       order by c.fecha desc limit 1)
    >= (select (valor)::numeric from config where clave = 'humedad_suelo_saturado'),
    false);
$$;
