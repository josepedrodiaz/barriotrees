-- Regar un árbol sano no suma (P5 de la auditoría de la ficha).
-- bien y feliz pasan a 0 puntos, y el front ya no ofrece el botón de riego para
-- esos estados: son los dos estados "sanos", no se riegan. El incentivo queda
-- solo en los sedientos, que es donde el agua hace falta (decisión 12).
update config
set valor = '{"muy_sediento": 25, "sediento": 15, "bien": 0, "feliz": 0}'::jsonb
where clave = 'puntos_riego';
