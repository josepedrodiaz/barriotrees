-- El sector se muestra tal cual en la ficha del árbol, así que es una etiqueta
-- para leer y no un slug. Lo sembré como 'galeria-central' y en pantalla se veía
-- exactamente así, feo. La demo dice "Galería central" y tiene razón.
update arboles set sector = 'Galería central' where sector = 'galeria-central';
