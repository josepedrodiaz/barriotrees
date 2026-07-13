# Arquitectura del código

Cómo está organizado el código de Árboles Gigantes y por qué. Si sos nuevo en el proyecto: leé esto (10 min) y después [CLAUDE.md](../CLAUDE.md) para el contexto de producto.

## Stack

- **Frontend:** SvelteKit como PWA (`vite-plugin-pwa`), TypeScript estricto.
- **Backend:** Supabase (Postgres + Auth + API autogenerada). Casi no hay backend propio: la lógica de servidor vive en SQL (funciones RPC) dentro de Postgres.
- **Por qué:** el QR abre una URL — la app tiene que cargar rápido con mala señal en la plaza. Svelte compila sin runtime (bundles chicos) y SvelteKit trae ruteo, layouts y carga de datos resueltos de fábrica: menos decisiones propias, más convención. Supabase gratis cubre de sobra la escala de una plaza.

## Principios (los 4 que ordenan todo)

1. **Organización por features, no por tipos.** No hay carpetas `components/` o `utils/` gigantes. Cada área de la app tiene su carpeta con todo lo suyo junto.
2. **Las reglas del juego son funciones puras.** Todo lo que decide algo del juego — estado del árbol, puntos, insignias — vive en `src/lib/domain/` como TypeScript puro: sin imports de Svelte ni Supabase, con tests unitarios. Es el único lugar donde están las reglas; los componentes solo las llaman y muestran el resultado.
3. **La integridad vive en Postgres.** Registrar un riego es una función RPC transaccional del lado del server: valida el cooldown, verifica proximidad, calcula puntos y otorga insignias. El cliente nunca escribe puntos ni insignias — pide "registrá este riego" y muestra lo que el server devuelve. Todas las tablas tienen RLS. Esto es el corazón del anti-trampa: no se puede sumar tocando el frontend.
4. **La base de datos es parte del repo.** Todo cambio de esquema es una migración en `supabase/migrations/`. Nada de tocar el panel de Supabase a mano para cambiar el esquema: cualquiera clona el repo y reproduce la base exacta.

## Estructura

```
src/
  routes/               # páginas (convención SvelteKit: carpeta = ruta)
    +layout.svelte
    +page.svelte        # home: árboles por urgencia + tus puntos
    arbol/[id]/         # ficha del árbol (acá aterriza el QR)
    admin/              # ABM de árboles + QRs
  lib/
    features/           # lógica y componentes de cada área
      riego/            # escanear, confirmar, "Regando…" con barra
      arbol/            # estado visual, historial
      premios/          # insignias, niveles, tabla de posiciones
      auth/             # Google, magic link, reclamo del riego anónimo
      admin/
    domain/             # ← reglas puras del juego, con tests (ver principio 2)
      estado.ts         # estadoArbol(diasSinRiego, F) → feliz/bien/sediento/muySediento
      puntos.ts         # calcularPuntos(estado, hora, ...)
      insignias.ts      # evaluarInsignias(historial, ...)
    server/             # helpers que solo corren en el server (claves, etc.)
    supabase.ts         # cliente único de Supabase
    ui/                 # componentes compartidos (botón, ícono del árbol)
  app.css
supabase/
  migrations/           # esquema versionado, en orden
  functions/            # edge functions si hacen falta (por ahora no)
docs/                   # decisiones y especificaciones
```

**Regla de dependencias:** `routes → features → domain/lib`. `domain/` no importa de nadie. Una feature no importa de otra feature; si dos necesitan lo mismo, eso baja a `domain/` o `ui/`.

## Convenciones

- **Idioma:** los conceptos del juego en español (`arbol`, `riego`, `insignia`, `calcularPuntos`, tabla `riegos`); lo técnico en inglés como es estándar (`handleClick`, `fetch`, `load`). El código habla el mismo idioma que las comisiones y la documentación. Sin tildes ni eñes en identificadores (`arbol`, no `árbol`).
- **Nombres:** componentes en PascalCase (`FichaArbol.svelte`), funciones y variables en camelCase, tablas y columnas en snake_case (`riegos.arbol_id`).
- **Git:** branch por ticket con la key (`feature/BT-11-circuito-riego`) — además así arranca solo el time-tracker. Commits cortos prefijados con el ticket: `BT-11 registra riego via RPC`. PR a `main` con CI verde.
- **Tipos desde el esquema:** `supabase gen types typescript` genera los tipos de la base; el frontend no puede desincronizarse del esquema. Se regeneran en cada migración.

## Calidad

- **TypeScript estricto** (`strict: true`), sin `any` salvo justificado en comentario.
- **ESLint + Prettier**: el formato no se discute; corre en pre-commit y CI.
- **Tests:** Vitest sobre `domain/` (las reglas del juego, cobertura alta acá) y sobre las funciones RPC de Postgres (pgTAP o tests de integración). Los componentes de UI no llevan tests unitarios en el MVP — la UI se prueba usándola.
- **CI (GitHub Actions):** lint + tests + build en cada PR. Rojo no se mergea.

## Decisiones registradas

Las decisiones de producto viven en [CLAUDE.md](../CLAUDE.md) ("Decisiones ya tomadas"). Las de arquitectura, acá. Cambiar algo de este documento se conversa antes, igual que las de producto.

## Setup para un dev nuevo

1. Clonar el repo, `npm install`.
2. Crear `.env` desde `.env.example` (URL y anon key del proyecto Supabase — pedirlas a Pedro).
3. `npx supabase start` (base local con Docker) o apuntar al proyecto compartido.
4. `npm run dev` y abrir el link.
5. `npm test` para correr los tests de dominio.
