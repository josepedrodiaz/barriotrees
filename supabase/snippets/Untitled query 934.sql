insert into arboles (codigo, especie_id, nombre, sector, lat, lng, activo)
select 'prueba-0' || g, (select id from especies limit 1),
       'Árbol de prueba ' || g, 'sector-a', -34.92, -57.95, true
from generate_series(1,3) g;