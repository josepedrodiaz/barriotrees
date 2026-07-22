# Relevamiento de árboles (censo de posiciones)

La herramienta para georreferenciar los árboles de la plaza es [tools/relevamiento.html](../tools/relevamiento.html), publicada en **https://www.josepedrodiaz.com/barriotrees/** (rama `gh-pages`).

## Qué hace

- Mapa satelital con el plano municipal superpuesto (se alinea con 3 esquinas arrastrables).
- Un pin por árbol: se pone tocando el mapa, o con **"Árbol en mi GPS"** parado al lado del árbol (el pin se ajusta arrastrando). Corte por precisión de GPS y aviso de duplicados.
- ABM de especies, sectores predefinidos, modo hilera, y un modo prueba separado para ensayar sin ensuciar los datos reales.
- **Exportar/copiar JSON**, y combinación de los JSON de varias personas con dedupe (para hacer el censo en grupo).
- **Carga de escritorio + verificación en campo (BT-36):** con el plano superpuesto, cada pin que se pone nace con `src: "plano"` y `verificado: false` (pin con borde punteado, tag "sin verificar" en la lista). Otro día, en la plaza, se toca el pin y el botón **"✓ Lo vi en la plaza — confirmar"** lo marca verificado (editar/borrar ya existían). La lista tiene filtro "solo sin verificar" con contador. Los pines por GPS nacen verificados (estás parado al lado); los registros viejos sin el campo se tratan como verificados. Dato de la comisión de arbolado (jul 2026): salvo las hileras de jacarandá, el plano coincide con la realidad — la carga desde plano es casi-definitiva y la caminata es control.

## ⚠️ Dónde viven los datos

La herramienta guarda todo en el **localStorage del navegador donde se usa** (clave `bt_relevamiento_v2`) — no hay servidor. Si se borra el navegador, se pierde el relevamiento: **exportar el JSON apenas se termina una sesión de censo** y respaldarlo acá.

## Relevamientos hechos

| Fecha | Qué | Respaldo | Estado |
|---|---|---|---|
| 08-jul-2026 | Galería central: 10 jacarandás (por Pedro, GPS + ajuste en mapa) | [relevamiento-jacarandas.json](relevamiento-jacarandas.json) | Cargado a la base (migración `20260714120000`) como `jaca-01`…`jaca-10` |

**Convención:** la etiqueta `N` del relevamiento = código `jaca-0N` en la base. Las chapitas QR físicas deben colgarse respetando esa numeración (la chapita `jaca-03` va al árbol marcado como 3).

## Pendiente

- Censar Sector A, Sector B y perimetrales (idealmente en grupo, combinando JSON).
- Pasar la carga de posiciones al panel admin de la app (BT-19) para no depender de migraciones.
