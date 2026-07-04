# BarrioTrees 🌳

App gamificada para que los vecinos cuidemos los árboles jóvenes de la plaza: llenás el balde en el bebedero, regás, escaneás el QR del árbol y sumás.

## La idea

Los árboles recién plantados necesitan riego constante, especialmente en verano. BarrioTrees convierte ese cuidado en un juego comunitario: cada riego registrado suma puntos al vecino y mejora el estado del árbol en la app.

## Loop principal

1. Cada árbol joven tiene una chapita con QR único
2. El vecino llena el balde en el bebedero de la plaza y riega
3. Escanea el QR y el riego queda registrado
4. Suma puntos, el ícono del árbol mejora, desbloquea premios

## El árbol - perfil digital

- Ficha por árbol: especie, fecha de plantación, foto
- Estado visual según días sin riego: sediento / ok / feliz
- El ícono del árbol evoluciona según el nivel de riego alcanzado. Es solo visual, para gamificar: no comunica cambios físicos reales del árbol
- Historial de riegos: quiénes y cuándo
- Ponerle nombre al árbol es un premio: se desbloquea a los N riegos y se elige por votación entre quienes lo regaron

## Gamificación

- Niveles de cuidador con beneficios según el nivel de riego alcanzado
- Puntos por riego con bonus: árbol sediento, ola de calor, horario recomendado
- Rachas semanales de riego
- Badges: Primer riego, Madrugador, Rescatista, Verano heroico, etc.

## Comunidad

- Ranking semanal y mensual del barrio
- Feed de actividad
- Metas colectivas con premio comunitario

## Modo verano

- Frecuencia objetivo de riego por especie y edad, más exigente en verano
- Alertas push cuando un árbol lleva días sin agua
- Puntos dobles en días de calor extremo

## Anti-trampa

- Cooldown: un mismo árbol no suma dos riegos en menos de X horas
- Geolocalización al escanear
- Foto del riego opcional para badges especiales

## Admin

- Alta y baja de árboles, generación de QRs imprimibles
- Dashboard: árboles en riesgo, riegos por semana, vecinos activos

## Decisiones de producto

- Web app PWA mobile-first, sin app nativa: el QR abre el navegador, cero fricción. Funciona en iPhone y Android con un solo deploy
- Registro simple: nombre + mail o teléfono
- Debe funcionar con mala conectividad: guardar el riego offline y sincronizar

## Pendientes

- Definir el MVP
- Nombre del rol del vecino: cuidador, tutor u otro
- Stack técnico
