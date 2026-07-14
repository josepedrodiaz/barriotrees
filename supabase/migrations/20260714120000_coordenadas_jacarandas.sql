-- Coordenadas reales de los 10 jacarandás de la galería central.
-- Fuente: relevamiento de Pedro en la plaza (08-jul-2026) con la herramienta
-- tools/relevamiento.html (respaldo del JSON en docs/relevamiento-jacarandas.json).
-- La etiqueta N del relevamiento corresponde a jaca-0N: las chapitas QR físicas
-- deben colgarse respetando esa numeración.
-- Con lat/lng cargadas, registrar_riego pasa a exigir proximidad (radio en config).

update arboles set lat = -34.97879264721342, lng = -58.02040327572772  where codigo = 'jaca-01';
update arboles set lat = -34.97883880235323, lng = -58.020347223780824 where codigo = 'jaca-02';
update arboles set lat = -34.97888465182149, lng = -58.02028648613253  where codigo = 'jaca-03';
update arboles set lat = -34.9789189033647,  lng = -58.02023846302332  where codigo = 'jaca-04';
update arboles set lat = -34.97895433745614, lng = -58.02017864961402  where codigo = 'jaca-05';
update arboles set lat = -34.978817454400975, lng = -58.020013880595656 where codigo = 'jaca-06';
update arboles set lat = -34.97877032404781, lng = -58.02007119797397  where codigo = 'jaca-07';
update arboles set lat = -34.97872838494665, lng = -58.02011703285473  where codigo = 'jaca-08';
update arboles set lat = -34.97867548281069, lng = -58.02017497281731  where codigo = 'jaca-09';
update arboles set lat = -34.97864185621449, lng = -58.020219814115144 where codigo = 'jaca-10';
