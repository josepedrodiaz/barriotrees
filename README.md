# Árboles Gigantes 🌳

**[arboles-gigantes.vercel.app](https://arboles-gigantes.vercel.app)**

Un juego del barrio para cuidar los árboles jóvenes de la plaza. Regás un arbolito con el balde, escaneás su chapita QR y sumás puntos. El árbol te lo agradece a su manera: su ícono se pone más verde, le crece follaje y, si está bien cuidado, florece.

Sabemos que los árboles recién plantados necesitan riego constante durante sus primeros veranos. Árboles Gigantes convierte ese cuidado en un juego comunitario.

## Cómo se juega

1. **Buscá un árbol con sed.** La app te muestra cuáles necesitan agua ahora, ordenados por urgencia.
2. **Llená el balde** en el bebedero de la plaza y regá.
3. **Escaneá su chapita QR.** El árbol te reconoce: tenés que estar ahí, al lado, para que el riego cuente.
4. **Sumá puntos y ganá premios.** Un árbol sediento paga más que uno feliz — el juego te lleva justo a donde hace falta el agua.

La sed de cada árbol no es un contador ciego de días: se calcula con el clima real de la plaza (lluvia y evaporación, actualizados todos los días). Si llovió fuerte, la app te avisa que hoy la lluvia trabajó por todos.

## Los premios se tocan

Las insignias no viven solo en la pantalla: **cada logro permanente es un pin físico real**, hecho a mano en el barrio, que se entrega en mano mostrando un QR de canje. Hay una escalera de siete insignias por puntos — la primera se gana con el primer riego, la séptima la van a alcanzar muy pocos — y aparte las de mérito: Rescatista (salvar árboles muy sedientos), Madrugador, Sereno.

También hay tabla de posiciones del barrio, y se viene más: títulos rotativos que se defienden semana a semana, la tutela de un árbol propio, notificaciones cuando un árbol te necesita.

## Sin fricción, a propósito

- **No hay app que instalar:** el QR abre la página del árbol en el navegador. Funciona en cualquier teléfono, y si querés la instalás como PWA.
- **Regás primero, cuenta después:** tu primer riego suma sin registrarte. La cuenta (Google o enlace mágico) llega recién cuando querés guardar tus puntos.
- **Pensada para la señal floja de la plaza:** liviana, sin fotos pesadas, con el árbol dibujado por código.

## La plaza

El proyecto arranca en la **Plaza Gigante del Oeste** (La Plata), junto a las comisiones de cultura y arbolado del barrio. Lanzamiento: **21 de septiembre de 2026**, Día de la Primavera, con el primer riego colectivo y la entrega de los primeros pines.

## Para curiosos técnicos

PWA en SvelteKit + Supabase (Postgres, RPC y RLS para la integridad del juego), clima diario de Open-Meteo vía GitHub Actions, deploy en Vercel. Las reglas del juego son funciones puras y el anti-trampa vive en la base, no en el cliente. Detalle de arquitectura en [docs/arquitectura.md](docs/arquitectura.md).
