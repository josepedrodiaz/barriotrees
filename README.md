# Árboles Gigantes 🌳

App gamificada para que los vecinos cuidemos los árboles jóvenes de la plaza: llenás el balde en el bebedero, regás, escaneás el QR del árbol y sumás.

## La idea

Los árboles recién plantados necesitan riego constante, especialmente en verano. Árboles Gigantes convierte ese cuidado en un juego comunitario: cada riego registrado suma puntos al vecino y mejora el estado del árbol en la app.

## Circuito principal

1. Cada árbol joven tiene una chapita con QR único
2. El vecino llena el balde en el bebedero de la plaza y riega
3. Escanea el QR y el riego queda registrado
4. Suma puntos, el ícono del árbol mejora, desbloquea premios

## El árbol - perfil digital

- Ficha por árbol: especie, fecha de plantación (sin foto: todo con iconos, para no pesar en mala conectividad)
- Estado visual según días sin riego: sediento / bien / feliz
- El ícono del árbol evoluciona según el nivel de riego alcanzado. Es solo visual, para gamificar: no comunica cambios físicos reales del árbol
- Historial de riegos: quiénes y cuándo
- Ponerle nombre al árbol es un premio: se desbloquea a los N riegos y se elige por votación entre quienes lo regaron

## Pantalla inicial

- Arranca con las alarmas de los árboles más sedientos ahora, ordenados por urgencia (días sin riego vs. frecuencia objetivo de la especie)
- Es el gancho: abrís la app y ya sabés a qué árbol ir

## Gamificación

Tres tipos de premio, cada uno con su función:

- **Insignias (permanentes):** se ganan y quedan para siempre. Premian que arranques. Primer riego, Madrugador, Rescatista (regar árboles muy sedientos N veces), Verano heroico
- **Banderas / títulos rotativos (estilo Strava "Leyenda"):** los tenés mientras seas el mejor en una ventana móvil de X días. Se defienden y se pueden perder. Leyenda de un árbol (quien más lo regó en los últimos 30 días), Leyenda del barrio. Es la competencia viva
- **Niveles de cuidador:** progresión por hitos, con beneficios. Suben, no bajan
- **Tutela (premio Tutor):** vínculo 1-a-1 con un árbol. Ganás la tutela de un árbol específico, tu nombre queda en su ficha. El honor más alto — no es un puntaje, es una relación

Puntos por riego con extra: árbol sediento, ola de calor, horario recomendado. Rachas semanales de riego.

El exceso de riego no quita puntos. Un árbol ya feliz da 0 o pocos puntos (el extra vive en los sedientos) y al escanearlo un mensaje te redirige a los sedientos cercanos. La regulación es por diseño, sin castigo.

Cada desbloqueo muestra un copy muy motivador, no solo el ícono. La idea es que ganar un premio se sienta.

## Comunidad

- Tabla de posiciones semanal y mensual del barrio
- Muro de actividad
- Metas colectivas con premio comunitario

## Modo verano

- Frecuencia objetivo de riego por especie y edad, más exigente en verano
- Alertas por notificación cuando un árbol lleva días sin agua
- Puntos dobles en días de calor extremo

## Anti-trampa

- Tiempo de espera: un mismo árbol no suma dos riegos en menos de X horas
- Geolocalización al escanear
- Foto del riego opcional para insignias especiales

## Admin

- Alta y baja de árboles, generación de QRs imprimibles
- Panel: árboles en riesgo, riegos por semana, vecinos activos

## Decisiones de producto

- App web PWA orientada a celular, sin app nativa: el QR abre el navegador, cero fricción. Funciona en iPhone y Android con una sola publicación
- Registro simple: nombre + correo o teléfono
- Debe funcionar con mala conectividad: guardar el riego sin conexión y sincronizar

## Pendientes

- Definir el MVP
- Nombre del rol del vecino: cuidador, tutor u otro
- Tecnologías
