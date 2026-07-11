# Árboles Gigantes 🌳

App web gamificada para que los vecinos rieguen los árboles jóvenes recién plantados de la plaza del barrio, usando el balde y el bebedero de la plaza. Cada árbol tiene un QR: regás, escaneás, sumás puntos y el árbol "mejora" en la app.

Repo: https://github.com/josepedrodiaz/barriotrees (público)
Estado: solo README con el punteo de requerimientos. No hay código todavía.

## Contexto del proyecto

- Proyecto comunitario/vecinal de Pedro (josepedrodiaz@gmail.com)
- Los árboles son jóvenes y necesitan mucho riego, especialmente en verano — la app existe para resolver eso
- Prioridad: que sea MUY gamificada, con muchos premios, distintivos y niveles
- **La plaza es la Plaza Gigante del Oeste** (La Plata, 49 bis/50 entre 174 bis/175 bis). Plano y especies en [docs/especies-umbrales.md](docs/especies-umbrales.md). La **galería central son jacarandás** (se replantaron porque los del plano original se murieron) — dan a la ventana de la oficina de Pedro y son **zona prioritaria** del proyecto.
- **Se hace en conjunto con dos comisiones de vecinos del barrio: la comisión de cultura y la comisión de arbolado.** Pedro presenta el proyecto a la comisión de cultura, y esa comisión lleva la batuta / centraliza todo el proyecto. (Implica: las decisiones grandes se validan con cultura; arbolado aporta lo técnico de los árboles.)
- **Lanzamiento: 21 de septiembre de 2026 (Día de la Primavera).** Fecha límite dura. Encaja perfecto: arranca la temporada de riego y el Día de la Primavera es el evento de lanzamiento natural (el "bautismo de la plaza"). Desde hoy (jul 2026) son ~2,5 meses → obliga a un MVP chico y bien cortado.
- **Los logros permanentes se entregan como pines físicos reales.** La esposa de Pedro tiene una pinera (máquina de hacer pines), así que los premios que no se pierden (insignias permanentes, y por extensión niveles/tutela) se materializan en un pin real entregable. Las banderas rotativas NO son pines (se pierden). Esto hace el premio tangible y refuerza la distinción permanente vs. rotativo.

## Decisiones ya tomadas (no reabrir sin preguntar)

1. **Nombre: Árboles Gigantes.** El barrio se llama Gigante del Oeste; los árboles hoy son chiquitos y con riego y cuidado queremos que sean gigantes — el nombre cuenta esa historia. (Nombre de trabajo anterior: "BarrioTrees", descartado por estar en inglés — todo va en español.) Descartados antes: GuardaPlaza/Guardianes (muy militar), CuidaPlaza, Bosquecito, "Barriotreees" con tres e. **Nota técnica:** el repo y la URL siguen usando el slug `barriotrees` por ahora (no romper los QR ya publicados); se puede renombrar cuando haya dominio final.
2. **Web app PWA mobile-first, NO app nativa.** Razón clave: el QR abre una URL en el navegador — cero fricción, sin App Store, una sola publicación cubre iPhone y Android.
3. **El ícono del árbol evoluciona solo como representación visual** del nivel de riego alcanzado. NUNCA mensajes tipo "le salió una rama" que sugieran cambios físicos reales del árbol — la gente los tomaría literalmente. Los premios reales son beneficios por nivel.
4. **Ponerle nombre al árbol es un premio, no gratis.** Se desbloquea a los N riegos y el nombre se elige por votación entre quienes lo regaron.
5. **Progresión separada en dos capas:** estado/salud (rápido, reactivo, respuesta inmediata al regar) vs. progreso de largo plazo (lento, por hitos).
6. **Los premios se dividen en tres tipos** (esto ordena todo el sistema de gamificación):
   - **Insignias (permanentes):** logros que se ganan y quedan para siempre. Premian que el vecino *arranque*. Ej: Primer riego, Rescatista, Madrugador.
   - **Banderas / títulos rotativos (modelo Strava "Leyenda"):** se tienen mientras se es el mejor en una ventana móvil de X días. Se defienden y se pueden perder. Premian que el vecino *siga*. Ej: Leyenda de un árbol (quien más lo regó en los últimos 30 días), Leyenda del barrio. Son la competencia viva del sistema — sin esto, el que ya tiene todas las insignias deja de jugar.
   - **Niveles de cuidador (progresión):** suben por hitos, no bajan.
7. **Cada desbloqueo de premio lleva un copy MUY motivador.** No se muestra solo el ícono: se muestra un texto que emocione y le dé peso a lo que ganó. Ej. del premio Tutor: "No es un ícono, es una relación." Aplica a todos los premios (insignias, banderas, niveles, tutela).
8. **"Tutor" reservado para un premio especial de tutela.** El tutor es el palo que sostiene al arbolito, así que el premio es un vínculo 1-a-1 con un árbol: se gana la tutela de un árbol específico, el nombre del vecino queda en su ficha, es el referente de ese árbol. Es el honor más alto — no es un puntaje, es una relación. Semi-permanente: se mantiene mientras el vecino siga activo con ese árbol. (Pendiente: definir si la tutela es a un solo árbol o a varios.)
9. **Alarmas de árboles sedientos en la pantalla inicial.** La pantalla inicial arranca mostrando los árboles que más necesitan agua ahora, ordenados por urgencia (días sin riego vs. frecuencia objetivo de la especie). Es el gancho para abrir la app y saber a dónde ir; además alimenta la insignia Rescatista.
10. **Rescatista:** insignia permanente que se gana al regar árboles en estado *muy sediento* (el crítico/rojo, no el amarillo) N veces. (Pendiente: fijar N — propuesta inicial 5.)
11. **Sin foto en el perfil del árbol — todo con iconos.** La foto pesa y arruina la experiencia en mala conectividad (que es requisito). El árbol ya tiene su ícono evolutivo como identidad visual, y el QR lo identifica físicamente. La foto del riego se mantiene solo como opcional en anti-trampa (prueba para insignias, no identidad).
12. **El exceso de riego NO quita puntos.** Castigar va contra el tono cálido y confunde al que regó con buena intención. La regulación es por diseño: (a) el tiempo de espera evita dos riegos seguidos al mismo árbol; (b) un árbol ya feliz/bien da 0 o pocos puntos — el extra vive en los sedientos; (c) al escanear un árbol ya bien regado, un mensaje redirige a los sedientos cercanos ("Este ya está feliz, hay 3 sedientos cerca 👉"). La escasez de puntos en árboles felices hace el trabajo, sin retar a nadie, y desalienta tirar agua de más a un arbolito joven.
13. **Stack elegido: Supabase (plan gratis) + PWA en JS + Web Push.** Se evaluó hacerlo en PHP (lo que Pedro ya sabe) sobre su propio servidor, pero se descartó: alojar PHP gratis y confiable no existe, y el servidor casero no sirve para una app pública (IP dinámica, CGNAT, tiempo activo — un QR muerto en la plaza mata el proyecto). el plan gratis de Supabase cubre de sobra la escala (una plaza). Definiciones que acompañan:
    - **Frontend:** PWA en JS (Vite+React o SvelteKit). Inevitable: service worker, sin conexión y notificaciones viven en el navegador sea cual sea el backend.
    - **Backend:** Supabase administrado — Postgres + autenticación + almacenamiento + la API autogenerada. Poco "backend" propio; lógica del lado del servidor en SQL o edge functions si hace falta.
    - **Acceso:** Google como opción principal (un toque, casi todos ya tienen la sesión iniciada = mínima fricción en el primer riego) + correo con enlace mágico de respaldo para quien no quiere/tiene Google. Ambos gratis en Supabase. Teléfono se descarta por ahora (el SMS cuesta). Gotcha: activar el acceso con Google pide crear un proyecto en Google Cloud y hasta verificar la app puede aparecer una pantalla de "app no verificada" (se resuelve, es un paso de configuración).
    - **Funcionar sin conexión: FUERA del MVP.** Pelea con el anti-trampa (¿confiás en la hora del teléfono si sincroniza 3hs después?) y mete mucha complejidad. MVP con conexión, con interfaz optimista (muestra "regado ✓" y reintenta). Sin conexión real es v2 si se comprueba que hace falta.
    - **Tablas de posiciones/banderas:** calcular en el momento de la consulta, no con tarea programada (cron). A esta escala sobra. Cron recién cuando duela.
    - **Ojo con Supabase:** el plan gratis pausa el proyecto tras ~1 semana inactivo (riesgo en app de temporada). Solución gratis: un ping diario con cron externo (cron-job.org / GitHub Action) lo mantiene despierto.
    - **Dominio:** gratis para arrancar (subdominio). HTTPS lo da el alojamiento, así que PWA/geo/notificaciones funcionan.
14. **Onboarding: primero riega, después crea la cuenta.** El vecino puede regar y sumar sin loguearse; recién después se le ofrece crear cuenta ("guardá tus puntos con Google"). Se le da el gustito antes de pedirle nada — baja la fricción justo en el momento crítico (el primer riego). A resolver: cómo se atribuye ese primer riego anónimo a la cuenta que se crea enseguida (ej: un id de dispositivo/sesión temporal que se "reclama" al registrarse) sin abrir un agujero de anti-trampa. **El que escanea un QR llega en frío (sin saber qué es): el primer ingreso muestra una bienvenida corta y motivadora que explica qué es y qué hacer, antes de la ficha del árbol.**
15. **Umbrales de riego administrables, con default por especie.** Cada especie tiene una frecuencia objetivo `F` (días entre riegos, árbol joven, verano) y el estado (feliz/bien/sediento/muy sediento) se deriva de los días sin riego vs. `F` con multiplicadores globales. Todo editable por el admin. Defaults y tabla de especies en [docs/especies-umbrales.md](docs/especies-umbrales.md). A validar con la comisión de arbolado.
16. **La tutela (Tutor) desbloquea capacidades de curador liviano** sobre la ficha del árbol tutelado: editar la altura estimada y agregar anotaciones. Es lo que la vuelve un rol, no solo una medalla. (Tutela es v2; la capacidad queda definida.)
17. **El riego se valida con escaneo del QR físico + proximidad (geoloc) — NO se resuelve desde la app.** Es el corazón anti-trampa y de la integridad del juego: no se puede sumar tocando botones; hay que estar físicamente en el árbol y escanear su QR, y la app confirma "QR válido + estás cerca" antes de registrar. La pantalla inicial muestra a dónde ir (info/urgencia), pero el punto solo se gana en el árbol. Cualquier demo/maqueta debe reflejar esto.
18. **El riego tiene una duración mínima ("Regando…" con barra de progreso) que además educa.** Al confirmar, corre unos segundos mostrando un tip sobre el árbol / cómo regar bien, y recién al terminar registra. Doble función: refuerza el anti-trampa (no se puede escanear-y-listo masivo, cada riego lleva su tiempo real, más allá del tiempo de espera) y aprovecha el momento para enseñar. (En el MVP definir la duración real.)

## Requerimientos (resumen; el detalle está en README.md)

- Circuito: llenar balde en bebedero → regar → escanear QR del árbol → riego registrado → puntos + premios
- Perfil por árbol: especie, fecha plantación, foto, estado visual (sediento/bien/feliz según días sin riego), historial de riegos
- Gamificación: niveles de cuidador con beneficios, puntos con extra (árbol sediento, ola de calor, horario recomendado), rachas, insignias (Primer riego, Madrugador, Rescatista, Verano heroico...)
- Comunidad: tablas de posiciones, muro de actividad, metas colectivas con premio comunitario
- Modo verano: frecuencia objetivo por especie/edad, alertas por notificación por árbol sin riego, puntos dobles en calor extremo
- Anti-trampa: tiempo de espera por árbol, geolocalización al escanear, foto opcional
- Admin: ABM de árboles, QRs imprimibles, panel de árboles en riesgo
- Técnico: registro simple (nombre + mail o teléfono), tolerante a mala conectividad (riego sin conexión + sincronización)

## MVP (v1) — CERRADO

Criterio de corte: **¿qué tiene que poder hacer la app el 21/09 en la plaza?** Los vecinos hacen su primer riego en vivo; la app tiene que escanear, registrar, dar algo que se sienta, y que un par se lleven un pin. Todo lo que no sirva a eso, afuera.

**Entra en el MVP:**
- **El circuito completo:** escanear QR → página del árbol → botón "Regué" → registra riego → puntos (base + extra si estaba sediento) → el árbol cambia de estado (sediento/bien/feliz) según días sin riego vs. frecuencia objetivo.
- **Identidad mínima:** riega primero, cuenta después. Acceso con Google + enlace mágico. El riego anónimo se reclama al crear cuenta.
- **Pantalla inicial:** árboles ordenados por urgencia (sedientos arriba) + tus puntos.
- **Perfil del árbol:** especie, fecha, estado (ícono), historial de riegos.
- **Anti-trampa mínimo:** tiempo de espera por árbol + geoloc.
- **Gamificación mínima (acá viven los pines):** puntos + tabla de posiciones simple del barrio + 2–3 insignias permanentes que se entregan como **pin real** (Primer riego, Rescatista, capaz Madrugador). Es el gancho del evento y lo mejor para mostrarle a la comi de cultura.
- **Admin:** crear árboles + generar QRs imprimibles (sin esto no hay qué escanear el día del lanzamiento).

**Fuera del MVP (con motivo):**
- **Banderas (Leyenda):** el día 1 nadie tiene historia de 30 días → la bandera está vacía. Entra en v1.1, justo cuando empieza a significar algo.
- **Tutela (Tutor):** necesita historia acumulada para ser un honor. v2.
- **Notificaciones:** v1.1. La pantalla inicial ya cubre el "a dónde voy" sin notificaciones.
- **Familias, metas colectivas, muro de actividad, resumen de temporada, canjes con comercios, sin conexión real, modo verano avanzado:** v2 / más adelante.

**Hoja de ruta en tres tiempos:**
1. **MVP (21/09, lanzamiento):** circuito + identidad + pantalla inicial + puntos + 2–3 pines + admin.
2. **v1.1 (semanas después, en temporada):** banderas Leyenda, notificaciones, modo verano (puntos dobles en calor), tabla de posiciones más completa.
3. **v2 (temporada que viene):** familias, tutela, metas colectivas, resumen de temporada, comercios.

**Notas:** el corte ya es ambicioso para ~2,5 meses con stack nuevo. Si se aprieta, lo primero que se sacrifica es el tabla de posiciones, después Madrugador; el piso intocable es circuito + un pin + admin. Los umbrales de estado por especie se cierran con la comisión de arbolado.

## Pendientes / próximos pasos

- [ ] Nombre del rol del vecino: candidatos "Cuidador" (favorito, tono elegido) o "Tutor" (doble sentido botánico: el tutor es el palo que sostiene al arbolito). Descartado "Guardián" por militar. Idea de niveles: Aprendiz → Cuidador → Gran Cuidador → Alma de la Plaza
- [ ] Diseñar el ícono/árbol visual y sus estados
- [ ] Idea suelta a evaluar: un resumen de temporada por árbol/vecino (tipo el resumen anual que hace Spotify)
- [ ] MVP: validar con la comisión de arbolado los umbrales por especie ya propuestos en [docs/especies-umbrales.md](docs/especies-umbrales.md) (frecuencia F y bandas de estado)
- [ ] MVP: confirmar qué insignias/pines entran en el lanzamiento (Primer riego seguro; Rescatista y Madrugador a confirmar)
- [ ] Fijar N para la insignia Rescatista (propuesta: 5 rescates de árbol muy sediento)
- [ ] Tutela (premio Tutor): definir si es a un solo árbol o a varios, y cómo se gana exactamente (más regado / tiempo sostenido)
- [ ] Definir las ventanas de tiempo de las banderas rotativas (ej: 30 días para Leyenda de árbol) y qué banderas existen
- [ ] Escribir los copies motivadores de cada premio (uno por insignia/bandera/nivel/tutela)
- [ ] **Reporte de peligros + premio "Centinela/Reportero" (idea de la comi de arbolado).** Amenaza real: las hormigas atacan a los árboles jóvenes. El vecino marca en la ficha "este árbol tiene tal problema" (hormigas, plaga, rama rota, etc.), el admin lo verifica y actúa/ayuda al árbol, y el reporte verificado da premio (insignia permanente o banderín rotativo — a definir cuál). Suma otra forma de cuidar más allá de regar. Probable v1.1/v2; definir tipos de peligro, flujo de verificación y qué premio da.

## Marketing / comunidad (pasada de ideas evaluadas)

- **El árbol es el cartel.** Cada chapita con QR es publicidad parada en la plaza, gratis. Que no diga solo "escaneá": que muestre gancho ("Regame y sumá. Leyenda actual: Marta 🚩"). Sumar un cartel físico en la plaza con el tabla de posiciones de la semana o el árbol más sediento.
- **Canal de WhatsApp propio, no invadir el grupo del barrio.** Crear un Canal de difusión (una sola vía: alertas de sedientos, tabla de posiciones). La gente lo sigue por voluntad, no satura a nadie. Al grupo del barrio se le avisa UNA vez que existe. Grupo con charla (fotos, piques por la bandera) recién si se quiere, más adelante.
- **Distribución por grupos, no de a uno.** Aliados que ya tienen gente junta: junta vecinal / sociedad de fomento, escuela (los pibes riegan + arrastran a los padres), club, parroquia.
- **Evento de lanzamiento** tipo "bautismo de la plaza": mostrar la app en vivo, que hagan el primer riego ahí. El primer riego es el momento clave del onboarding.
- **Premios con comercios locales (canje).** La panadería regala un café al Cuidador del mes. Todos ganan: publicidad barata para el comercio, premio real para el vecino, costo cero para el proyecto. Y los comercios difunden.
- **Familias (idea fuerte, evaluada — v2, NO MVP):** un grupo de usuarios arma una "familia" y las familias compiten entre sí. La "familia" no es solo la de sangre: puede ser un edificio/consorcio, una cuadra, un curso de la escuela, la barra del club. Valor: el puntaje individual deja afuera al que riega poco; la familia lo mantiene (te quedás por tu grupo). Encaja con las metas colectivas y la bandera rotativa ("Familia de la semana"). **Decisión de diseño clave: ordenar por PROMEDIO por miembro activo, no por suma total** (si es por suma total, gana siempre la más numerosa y las chicas no juegan); con un umbral mínimo de actividad para contar como miembro. Idea linda: una familia "adopta" un bosquecito (su territorio), que se cruza con la tutela individual (Tutor = tu árbol; familia = el bosque del grupo). Va DESPUÉS del MVP: amplifica un circuito que ya tiene que estar probado.

## Convenciones

- Todo en español rioplatense (voseo: "regás", "sumás")
- Tono cálido y comunitario, nada militar ni corporativo
