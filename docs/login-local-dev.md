# Login en local (desarrollo)

El login por **magic link** y por **Google** no sirve bien en local:

- **Google** no está habilitado en el Supabase local.
- **Magic link** entra en un **loop**: supabase-js usa flujo PKCE y guarda el
  verificador en el `localStorage` del origen exacto (`http://localhost:5173`).
  Si navegás por `127.0.0.1:5173`, o clickeás el link dos veces (el token es de
  un solo uso), al volver a `/auth/callback` no encuentra la sesión → vuelve
  null → te rebota a `/entrar`. Loop infinito.
- Además, el mail en local **no llega a tu Gmail**: lo captura el buzón interno
  (Inbucket/Mailpit) en `http://127.0.0.1:54324`.

## Solución: botón "Entrar como dev (local)"

En `/entrar`, **solo con `import.meta.env.DEV`**, aparece un botón
**🛠 Entrar como dev (local)** que hace `signInWithPassword` contra un usuario
admin sembrado por `supabase/seed.sql`:

```
usuario: josepedrodiaz@gmail.com   ·   contraseña: dev
```

Un click y entrás como admin, sin mail ni Google, sin PKCE.

**El email TIENE que ser `josepedrodiaz@gmail.com`.** `es_admin()` (migración
`roles_entregador`) decide admin por **email en `auth.users`**, NO por la columna
`perfiles.es_admin`. Con cualquier otro email entrás y las lecturas públicas
andan, pero **todo write de admin da 0 filas por RLS** (sin error): p. ej. mover
un pin en el mapa no persiste, aunque el header te muestre "admin" (eso lee la
columna vieja `perfiles.es_admin`, que ya no gobierna nada).

### Cómo usarlo

> El CLI de Supabase es una **devDependency**, no está global. Se usa con `npx`
> o con los scripts `npm run db:*`. `supabase` a secas da "command not found".

1. Levantá el stack local: `npm run db:start` (= `npx supabase start`).
2. Sembrá el usuario dev (lo crea el seed): `npm run db:reset` (= `npx supabase db reset`).
   - `db reset` corre las migraciones + `supabase/seed.sql`. El seed **solo** corre
     en local; prod se despliega por migraciones vía CI, nunca por seed.
3. `npm run dev` y entrá por **`http://localhost:5173`** (no `127.0.0.1`).
4. En `/entrar`, tocá **🛠 Entrar como dev (local)**.

### Notas

- `es_admin = true` te lo vuelve a poner cada `supabase db reset` (el seed corre
  de nuevo). No hace falta el `update` a mano.
- El seed usa `service_role` para poder setear `es_admin`, porque el trigger
  `proteger_campos_perfil` revierte ese campo para cualquiera que no sea admin
  ni service_role.
- El botón y el usuario **no existen en producción**: el botón está detrás de
  `import.meta.env.DEV` y el seed no corre en el deploy.
- Si el botón dice "No existe el usuario dev", te faltó el `supabase db reset`.

## Si se cuelga en "Buscando tu cuenta…" (o el botón dev no hace nada)

Síntoma: el login queda pendiente para siempre, la app muestra "Buscando tu
cuenta…" y en consola `signInWithPassword` devuelve un `Promise {<pending>}` que
nunca resuelve. **No es el login ni la base** (probado: pegándole directo al
servidor y llamando al cliente, funciona). Es el **Web Lock de auth de
supabase-js**: con varias pestañas de `localhost:5173` abiertas (o un service
worker viejo), una pestaña deja el lock tomado y toda operación de auth se cuelga
en TODAS las pestañas (el lock es compartido por origen).

Ya está mitigado en código: en dev el cliente usa un lock no-op
(`src/lib/supabase.ts`, gateado por `import.meta.env.DEV`; prod mantiene el lock).
Pero si tu navegador quedó con el estado trabado de antes:

1. **Cerrá TODAS las pestañas de `localhost:5173`** (así se suelta el lock).
2. Abrí **una** pestaña nueva y andá a `/entrar`.
3. Botón dev.

Si aun así se cuelga: F12 → Application → **Storage** (ítem del panel izquierdo) →
botón **"Clear site data"** (borra SW + caché + local/session storage + cookies,
mucho más que `localStorage.clear()`), y reabrí una sola pestaña.

Regla para no repetirlo: en local corré **solo `npm run dev`** (nunca `preview`
en el 5173, que sí registra service worker) y no dejes mil pestañas abiertas.

## Por qué el seed también repone grants

Un `db reset` local desde cero deja a `anon`/`authenticated` **sin SELECT/DML**
sobre las tablas base (en prod venían por el default histórico de Supabase, nunca
versionado). Sin eso, el cliente recibe **403** al leer `perfiles` (`cargarPerfil`),
`arboles`, etc., y el login "no cuaja". Por eso `seed.sql` repone esos grants —
**solo local**, no como migración (una migración correría en prod por CI).

El seed, después de reponer los grants, **vuelve a aplicar los `revoke` de la
auditoría de seguridad** (`insignias_ganadas` cerrado, `riegos.dispositivo_id` no
legible), para que local quede idéntico a prod, blindaje incluido. No tocar eso:
ver el detalle en las migraciones `20260716213000` y `20260920120000`.
