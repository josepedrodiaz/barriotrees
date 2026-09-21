-- jaca-NN codificaba la especie; se pasa a serial neutro 0NN. La URL ya es
-- /arbol/, el prefijo sobraba; la especie vive en especie_id (editable).
-- Rompe los QR/URLs viejos de esos árboles (asumido, no se usan aún).
update arboles
set codigo = lpad(split_part(codigo, '-', 2)::int::text, 3, '0')
where codigo ~ '^jaca-[0-9]+$';
