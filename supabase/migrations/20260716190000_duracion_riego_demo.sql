-- La duración de "Regando…" la había fijado en 20s a ojo; la demo usa 11 y es
-- la referencia (decisión 21). Además 11s alcanzan para lo que la pantalla
-- tiene que lograr: frenar el escaneo masivo y dejar leer un tip mientras el
-- árbol crece. Sigue siendo config: la comisión la mueve sin tocar código.
update config set valor = '11' where clave = 'duracion_riego_segundos';
