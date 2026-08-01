# Plaza y especies — umbrales de riego (valores por defecto administrables)

## La plaza

- **Plaza Gigante del Oeste**, La Plata. Calle 49 bis y 50, entre 174 bis y 175 bis.
- Plano de referencia: `L1_Gigante del Oeste_v2.pdf` (Subsecretaría de Planeamiento Urbano, Municipalidad de La Plata). Escala 1:350.
- Dos sectores en la plaza: **Sector A** y **Sector B**. Arbolado perimetral sobre las cuatro calles + arbolado interior.
- El plano trae la leyenda de especies (referencias A1–A15). Los círculos numerados del plano son las posiciones de los árboles; mapear cada posición a su especie es carga de datos del admin.

## ⚠️ La galería central son JACARANDÁS (cambió respecto del plano)

La galería del centro de la plaza figura en el plano con otra especie, pero **esos árboles se murieron al plantarlos y se replantaron con jacarandás** (*Jacaranda mimosifolia*). Es la galería que da a la ventana de la oficina de Pedro. **Zona prioritaria del proyecto** — es la que más importa hacer prosperar. (Candidata natural a "bosquecito" adoptable por una familia en v2, y a tutela.)

## Modelo de umbrales (cómo se calcula el estado) — VALIDADO por arbolado (ago 2026)

**Un solo criterio para todos los árboles del programa** (la comisión de arbolado simplificó la tabla por especie): apto para riego pasados **2 días** sin lluvia ni riego, sediento pasados **4**. El estado sale de los **días equivalentes de sed (`d`)** contra la frecuencia objetivo `F`:

| Estado | Rango (con F=2) | Color |
|--------|-------|-------|
| feliz | `d ≤ 1 día` | verde |
| bien | `1 < d ≤ 2` | neutro |
| **sediento** | `2 < d ≤ 4` | amarillo |
| **muy sediento** (cuenta para Rescatista) | `d > 4` | rojo |

Con las bandas de siempre (`0.5 / 1 / 2`), ese criterio 2/4 es exactamente **F = 2 para todas las especies del programa**. Antes la tabla proponía 2/3/4 según especie; arbolado lo unificó en 2.

**`d` no es días de calendario: es días *reales* de sed.** El balance hídrico (BT-33) mide el déficit de agua real (evapotranspiración diaria − lluvia, de Open-Meteo) y lo divide por `et0_referencia_mm` para pasarlo a "días equivalentes". Por eso:
- Si llueve, el árbol tarda más en ponerse sediento (la lluvia riega por vos).
- En una ola de calor se seca más rápido que el calendario.
- En un día seco de verano, 1 día real ≈ 1 día de sed → se cumple el 2/4 tal cual.

**Todo administrable:** `F` por especie, las bandas (`0.5 / 1 / 2`) y `et0_referencia_mm` son config editable por el admin. El admin puede subir la F de un árbol puntual si hace falta (`frecuencia_dias_override`).

### `et0_referencia_mm` = 4.5 (la vara de conversión)

Es el ET0 de un día típico de verano en La Plata: cuánto seca el suelo un día pleno de riego. Traduce la F de la especie (en días) al déficit en mm que tolera. **No cambia por estación** — el ET0 real diario ya hace ese trabajo (en invierno evapora ~1 mm/día y el árbol casi no se pone sediento; en verano ~4.5 y se cumple el 2/4). Por eso el multiplicador estacional quedó redundante (config en 1).

Fuente de autoridad: **INTA Balcarce** (el clima más parecido a La Plata en la provincia), ET0 de enero (verano pleno) ≈ **4.9 mm/día**, julio (invierno) ≈ 0.8. El 4.5 queda apenas por debajo del pico de enero — prudente, y el lanzamiento es en primavera (ET0 aún menor).

## Especies del programa (todas F=2)

Todas estas van a **F=2** (sediento >2 d, muy sediento >4 d):

*Jacaranda mimosifolia* (Jacarandá, galería central) · Kiri (A5) · Liquidámbar (A6) · Fresno rojo (A3) · Mandarino (A11) · Naranjo (A12) · Pomelo (A13) · Lapacho rosado (A2) · Tipa (A4) · Pezuña de vaca (A7) · Pezuña de vaca rosa (A8) · Ciruelo de jardín (A10) · Damasco (A14) · Ginkgo (A15) · Palmera washingtonia (A9).

**Preexistencias (A1, árboles ya establecidos): fuera del programa.** No participan del riego colectivo — quedan solo como referencia/información. Marcadas `en_programa = false`, no entran al ranking de sedientos.

## Tutela (Tutor) — capacidades sobre la ficha del árbol

El tutor de un árbol, además del honor, desbloquea **capacidades de curador liviano** sobre la ficha de SU árbol:
- **Editar la altura estimada** del árbol.
- **Agregar anotaciones** sobre el árbol (observaciones, estado, hitos).

Es lo que convierte la tutela en un rol y no solo una medalla. (Tutela es v2, pero la capacidad queda definida acá.)
