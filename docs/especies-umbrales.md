# Plaza y especies — umbrales de riego (valores por defecto administrables)

## La plaza

- **Plaza Gigante del Oeste**, La Plata. Calle 49 bis y 50, entre 174 bis y 175 bis.
- Plano de referencia: `L1_Gigante del Oeste_v2.pdf` (Subsecretaría de Planeamiento Urbano, Municipalidad de La Plata). Escala 1:350.
- Dos sectores en la plaza: **Sector A** y **Sector B**. Arbolado perimetral sobre las cuatro calles + arbolado interior.
- El plano trae la leyenda de especies (referencias A1–A15). Los círculos numerados del plano son las posiciones de los árboles; mapear cada posición a su especie es carga de datos del admin.

## ⚠️ La galería central son JACARANDÁS (cambió respecto del plano)

La galería del centro de la plaza figura en el plano con otra especie, pero **esos árboles se murieron al plantarlos y se replantaron con jacarandás** (*Jacaranda mimosifolia*). Es la galería que da a la ventana de la oficina de Pedro. **Zona prioritaria del proyecto** — es la que más importa hacer prosperar. (Candidata natural a "bosquecito" adoptable por una familia en v2, y a tutela.)

## Modelo de umbrales (cómo se calcula el estado)

Cada especie tiene una **frecuencia objetivo `F`**: días entre riegos para un **árbol joven en temporada de riego** (primavera–verano en La Plata). El estado sale de los **días desde el último riego (`d`)**:

| Estado | Rango | Color |
|--------|-------|-------|
| feliz | `d ≤ 0.5·F` | verde |
| bien | `0.5·F < d ≤ F` | neutro |
| **sediento** | `F < d ≤ 2·F` | amarillo |
| **muy sediento** (cuenta para Rescatista) | `d > 2·F` | rojo |

**Todo administrable:**
- `F` por especie (tabla de abajo). Es el valor por defecto; el admin lo edita.
- Los multiplicadores de las bandas (`0.5`, `1`, `2`) son globales por defecto, y se pueden afinar por especie si hace falta.
- **Multiplicador estacional:** fuera de temporada `F` se agranda (ej. ×2 en otoño, ×3 en invierno). El lanzamiento es en primavera, así que los valores de la tabla (verano) son los que rigen al arrancar.

> Los valores son un punto de partida horticultural, **a validar con la comisión de arbolado** (son los que saben). La app los toma como valor por defecto editable, no como verdad fija.

## Tabla de especies y frecuencia objetivo (árbol joven, verano)

| # ref | Especie | Común | F (días) | sediento | muy sediento |
|-------|---------|-------|:--------:|:--------:|:------------:|
| — | *Jacaranda mimosifolia* | **Jacarandá** (galería central) | **2** | >2 d | >4 d |
| A5 | *Paulownia tomentosa* | Kiri | 2 | >2 d | >4 d |
| A6 | *Liquidambar styraciflua* | Liquidámbar | 2 | >2 d | >4 d |
| A3 | *Fraxinus pennsylvanica* | Fresno rojo | 2 | >2 d | >4 d |
| A11 | *Citrus reticulata* | Mandarino | 2 | >2 d | >4 d |
| A12 | *Citrus × sinensis* | Naranjo | 2 | >2 d | >4 d |
| A13 | *Citrus × paradisi* | Pomelo | 2 | >2 d | >4 d |
| A2 | *Tabebuia impetiginosa* | Lapacho rosado | 3 | >3 d | >6 d |
| A4 | *Tipuana tipu* | Tipa | 3 | >3 d | >6 d |
| A7 | *Bauhinia forficata* | Pezuña de vaca | 3 | >3 d | >6 d |
| A8 | *Bauhinia variegata* | Pezuña de vaca rosa | 3 | >3 d | >6 d |
| A10 | *Prunus cerasifera* Atropurpurea | Ciruelo de jardín | 3 | >3 d | >6 d |
| A14 | *Prunus armeniaca* | Damasco | 3 | >3 d | >6 d |
| A15 | *Ginkgo biloba* | Ginkgo | 3 | >3 d | >6 d |
| A9 | *Washingtonia filifera* | Palmera washingtonia | 4 | >4 d | >8 d |
| A1 | Preexistencia | (árboles ya establecidos) | 7 | — | — |

**Criterio de los grupos:**
- **F=2 (alta):** crecimiento rápido y/o alta demanda de agua (Kiri, Liquidámbar), cítricos (sensibles al estrés hídrico), fresno, y el **jacarandá joven** mientras se establece.
- **F=3 (media):** especies rústicas de crecimiento medio; de adultas toleran sequía, pero de jóvenes necesitan riego sostenido (Tipa, Lapacho, Bauhinias, Prunus, Ginkgo).
- **F=4 (baja):** tolerante a sequía (palmera), aun así de joven pide agua.
- **Preexistencia:** ya establecidos, fuera del programa activo (riego de emergencia solo); `F` alto o directamente excluidos del ranking de sedientos.

## Tutela (Tutor) — capacidades sobre la ficha del árbol

El tutor de un árbol, además del honor, desbloquea **capacidades de curador liviano** sobre la ficha de SU árbol:
- **Editar la altura estimada** del árbol.
- **Agregar anotaciones** sobre el árbol (observaciones, estado, hitos).

Es lo que convierte la tutela en un rol y no solo una medalla. (Tutela es v2, pero la capacidad queda definida acá.)
