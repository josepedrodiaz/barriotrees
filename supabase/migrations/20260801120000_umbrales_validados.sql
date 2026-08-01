-- Umbrales de riego validados por la comisión de arbolado (BT-37, ago 2026).
--
-- La comisión simplificó la tabla por especie a un único criterio para TODOS
-- los árboles del programa: apto riego pasados 2 días, sediento pasados 4.
-- Con las bandas de siempre (0.5 / 1 / 2), eso es exactamente F = 2:
--   feliz ≤1 día · bien 1–2 · sediento >2 · muy sediento >4
-- Así que aplanamos la F de todas las especies del programa a 2. Antes había
-- 2/3/4 según especie; ese matiz queda sin efecto por decisión de arbolado.
update especies set frecuencia_dias = 2 where en_programa = true;

-- Las preexistencias (árboles ya establecidos) NO participan del riego
-- colectivo: quedan como referencia/decoración, fuera del ranking de sedientos.
-- Ya están marcadas en_programa = false; su F es irrelevante, la dejamos como
-- estaba. (Si algún día se cargan árboles de estas especies, la vista debería
-- filtrarlos del ranking — hoy no hay ninguno.)

-- El et0_referencia_mm (4.5) queda documentado con fuente de autoridad. Es la
-- vara que traduce la F de la especie (en días) al déficit en mm; NO cambia por
-- estación, porque el ET0 real diario (Open-Meteo) ya hace el ajuste estacional
-- solo. Fuente: INTA Balcarce (clima más cercano a La Plata), ET0 de enero
-- (verano pleno) ≈ 4.9 mm/día; el 4.5 queda apenas por debajo, prudente para
-- primavera (lanzamiento en septiembre).
update config
set descripcion = 'ET0 de referencia de verano en La Plata (mm/día). Traduce la F de la especie (días) a déficit en mm. Fuente: INTA Balcarce, ET0 enero ~4.9 mm/día. No cambia por estación: el ET0 real diario ya ajusta.'
where clave = 'et0_referencia_mm';

-- ---------- las preexistencias no entran al ranking de sedientos ----------
-- La vista se comparte entre la pantalla inicial (ranking) y la ficha del árbol
-- (escaneo de QR). NO la filtramos por en_programa —si no, una preexistencia
-- daría 404 al escanearla, y las queremos como referencia—. Solo exponemos la
-- columna en_programa para que la pantalla inicial pueda filtrarlas del ranking.
drop view v_arboles_estado;
create view v_arboles_estado as
select
  a.*,
  e.nombre_comun as especie_nombre,
  e.nombre_cientifico as especie_cientifico,
  e.en_programa,
  st.f_efectiva,
  st.dias_sin_riego,
  st.estado,
  round(f_deficit_mm(a.id), 1) as deficit_mm,
  coalesce((select sum(c.lluvia_mm) from clima_diario c where c.fecha > current_date - 3), 0) as lluvia_3d
from arboles a
join especies e on e.id = a.especie_id
cross join lateral f_estado_arbol(a.id) st
where a.activo;
