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
| **Sereno**     | 10 riegos después de las 19:00                    | Si da el tiempo |
| **Centinela**  | 3 reportes de peligro verificados por el admin    | v1.1 (con el flujo de reportes) |

Las dos franjas premiadas son las buenas para el árbol (sin sol fuerte, el agua no se evapora) — pero **la del atardecer es además la franja real de la plaza**: la vuelta del trabajo y de la escuela es cuando más gente circula. Si solo una entra al MVP, va Sereno antes que Madrugador. ("Sereno" por el fresco de la noche y por el que cuida de noche — si a la comisión no le gusta, alternativas: Nochero, Atardecer.)

## Reportes de peligro (v1.1)

El vecino marca en la ficha del árbol "tiene un problema": hormigas, plaga, rama rota, vandalismo. El admin lo verifica → si es real, actúa sobre el árbol y el reporte **suma puntos** (reportar es cuidar) y cuenta para Centinela.

## Banderas rotativas (v1.1, fuera del MVP)

Tipo "Leyenda" de Strava: quien más regó un árbol / el barrio en los últimos 30 días la tiene, y la defiende. Se pueden perder — por eso NO son pines. Entran cuando haya historia acumulada que las haga significar algo.

## Canje de pines

Al ganar cualquier insignia (escalera o mérito), la app muestra un **QR de canje único**. El que entrega los pines (comisión) lo escanea con la herramienta validadora: válido → pin en mano → marcado como canjeado. Imposible cobrar dos veces. **Entra al MVP**: es la mecánica de entrega del evento del 21/09.

## Anti-trampa (los números)

| Regla | Propuesta |
| ----- | --------- |
| Cooldown por árbol (global: el árbol ya recibió agua) | 12 horas |
| Cooldown por vecino+árbol (no repetir el mismo árbol) | 20 horas |
| Duración mínima de "Regando…" | 20 segundos |
| Validación de proximidad | dentro de ~50 m del árbol |

Todo del lado del servidor: el cliente no puede otorgar puntos ni insignias.

### Lo que el anti-trampa NO puede evitar (y por qué está bien)

**Un GPS falso se puede usar.** Cualquier teléfono con el modo desarrollador activado, o una extensión de navegador, puede mentir la ubicación: el navegador entrega esa posición falsa como si fuera real y el servidor no tiene forma de distinguirla. Es una limitación de la web, no de esta app — le pasa a Pokémon Go, a Strava y a todos.

Qué frena igual a un tramposo casual:
- **Hay que tener el QR del árbol.** No está en la app: está en la chapita, en la plaza. Para falsear un riego hay que haber ido al menos una vez y copiarse el código.
- **Los cooldowns limitan el techo.** Aunque alguien falsee todo, no puede sumar más que el que riega de verdad: son 12 h por árbol y 20 h por vecino+árbol.
- **Cada riego lleva sus 20 segundos.** No hay forma de hacer 50 riegos en un minuto.
- **La plaza es chica y el barrio se conoce.** Si alguien "riega" 10 árboles por día y nadie lo vio nunca con el balde, se nota. El historial de cada árbol es público en su ficha.

La decisión de fondo: **esto es un juego vecinal por pines, no un banco.** Blindarlo contra un tramposo decidido (foto obligatoria con revisión humana, verificación de red, etc.) costaría mucho trabajo y arruinaría la experiencia de los 99 vecinos honestos para frenar a uno. Si algún día aparece el problema real, se ataca ahí — y la carta más fuerte que tenemos es social, no técnica: los pines los entrega la comisión en la mano.

## Preguntas abiertas para la comisión del juego 👨‍👩‍👧

1. Nombres de los 7 peldaños — ¿estos, u otros? (el 7 = "Gigante del Oeste" es la apuesta fuerte)
2. Umbrales de puntos de la escalera — ¿la curva se siente bien?
3. Valores de puntos por riego — ¿25 por rescate es suficiente zanahoria?
4. ¿Rescatista con N=5 está bien?

(Resuelta: el validador de canje por QR entra al MVP — es la mecánica de entrega del evento.)
