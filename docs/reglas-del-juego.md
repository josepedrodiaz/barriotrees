# Reglas del juego — borrador para la comisión del juego

El reglamento completo del MVP en una página. **Todos los números son propuestas ajustables** (viven en configuración editable por admin, no en código): la comisión del juego los revisa y los cambia sin costo técnico. Los umbrales de estado por especie se validan aparte con la comisión de arbolado ([especies-umbrales.md](especies-umbrales.md)).

## El circuito

1. El vecino llena el balde en el bebedero y riega un árbol.
2. Escanea el QR del árbol. La app verifica: **QR válido + está físicamente cerca** (geolocalización).
3. Toca "Regué". Corre la pantalla "Regando…" (duración mínima, muestra un tip de riego/del árbol).
4. El riego queda registrado: suma puntos según el estado del árbol, y el árbol actualiza su estado.

Un riego vale si: el QR es real, la persona está cerca del árbol, y no cae dentro del tiempo de espera.

## Puntos

El puntaje premia regar **al que lo necesita**. Regar un árbol ya feliz casi no suma — el extra vive en los sedientos (y la app te redirige: "Este ya está feliz, hay 3 sedientos cerca 👉").

| El árbol estaba…    | Puntos propuestos |
| ------------------- | ----------------- |
| Feliz               | 1 (simbólico)     |
| Bien                | 5                 |
| Sediento            | 15                |
| Muy sediento 🔴     | 25 (es un rescate) |
| Reporte de peligro verificado (hormigas/plaga/daño) | 15 |

Extras que multiplican o suman (v1.1, fuera del MVP): horario recomendado de riego, puntos dobles en ola de calor.

**El exceso de riego no castiga.** Nunca se restan puntos. La regulación es la escasez: árbol feliz = 1 punto, y el cooldown impide riegos seguidos.

## La escalera (insignias de progresión) — el corazón del juego

**7 insignias por puntos acumulados, cada una más difícil que la anterior.** La primera se gana con el primer riego (imposible no ganarla); la séptima es muy, muy difícil — la alcanzan pocos, y eso es lo que la hace valiosa. Cada peldaño es **un pin físico real**. Son permanentes: se ganan y no se pierden.

| # | Nombre propuesto      | Umbral propuesto | Sensación buscada |
| - | --------------------- | ---------------- | ----------------- |
| 1 | **Primer Riego**      | 1 riego          | Instantánea. Te vas del primer riego con premio. |
| 2 | **Aprendiz**          | 100 pts          | Una semanita de regar. "Esto arranca fácil." |
| 3 | **Cuidador**          | 300 pts          | Ya sos habitué de la plaza. |
| 4 | **Gran Cuidador**     | 800 pts          | Un mes+ de constancia. Acá se separa la paja del trigo. |
| 5 | **Raíz del Barrio**   | 2.000 pts        | Media temporada de dedicación real. |
| 6 | **Alma de la Plaza**  | 4.500 pts        | Rareza. Se cuentan con una mano. |
| 7 | **Gigante del Oeste** | 10.000 pts       | Muy muy difícil: una temporada entera de compromiso excepcional. El nombre del barrio, reservado para quien lo merece. |

- La curva es exponencial a propósito: peldaños tempranos = enganche; peldaños altos = prestigio.
- Los umbrales se calibran cuando haya datos reales de la plaza (cantidad de árboles y frecuencia de riego); por diseño son editables por admin.
- **La escalera crece:** si 7 quedan cortas con el tiempo, se agregan peldaños por arriba o entre medio (el sistema lo permite; los pines nuevos se acuñan cuando haga falta).
- La escalera **unifica** lo que antes llamábamos "niveles de cuidador" e insignias de progresión: es un solo sistema, no dos. (A validar con la comisión del juego.)

## Insignias de mérito (aparte de la escalera)

Se ganan por **cómo** cuidás, no por cuánto acumulás. También permanentes, también pin.

| Insignia       | Criterio propuesto                                | ¿MVP? |
| -------------- | ------------------------------------------------- | ----- |
| **Rescatista** | 5 riegos a árboles muy sedientos 🔴               | Sí    |
| **Madrugador** | 10 riegos antes de las 9:00                       | Si da el tiempo |
| **Centinela**  | 3 reportes de peligro verificados por el admin    | v1.1 (con el flujo de reportes) |

## Reportes de peligro (v1.1)

El vecino marca en la ficha del árbol "tiene un problema": hormigas, plaga, rama rota, vandalismo. El admin lo verifica → si es real, actúa sobre el árbol y el reporte **suma puntos** (reportar es cuidar) y cuenta para Centinela.

## Banderas rotativas (v1.1, fuera del MVP)

Tipo "Leyenda" de Strava: quien más regó un árbol / el barrio en los últimos 30 días la tiene, y la defiende. Se pueden perder — por eso NO son pines. Entran cuando haya historia acumulada que las haga significar algo.

## Canje de pines

Al ganar cualquier insignia (escalera o mérito), la app muestra un **QR de canje único**. El que entrega los pines (comisión) lo escanea con la herramienta validadora: válido → pin en mano → marcado como canjeado. Imposible cobrar dos veces. (A definir: validador en MVP para el evento del 21/09, o v1.1 con marcado manual en el admin.)

## Anti-trampa (los números)

| Regla | Propuesta |
| ----- | --------- |
| Cooldown por árbol (global: el árbol ya recibió agua) | 12 horas |
| Cooldown por vecino+árbol (no repetir el mismo árbol) | 20 horas |
| Duración mínima de "Regando…" | 20 segundos |
| Validación de proximidad | dentro de ~50 m del árbol |

Todo del lado del servidor: el cliente no puede otorgar puntos ni insignias.

## Preguntas abiertas para la comisión del juego 👨‍👩‍👧

1. Nombres de los 7 peldaños — ¿estos, u otros? (el 7 = "Gigante del Oeste" es la apuesta fuerte)
2. Umbrales de puntos de la escalera — ¿la curva se siente bien?
3. Valores de puntos por riego — ¿25 por rescate es suficiente zanahoria?
4. ¿Rescatista con N=5 está bien?
5. ¿El validador de canje entra al MVP o marcamos a mano en el evento?
