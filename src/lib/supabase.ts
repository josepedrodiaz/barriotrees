import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';
import type { Database } from '$lib/database.types';

// Cliente único de Supabase para toda la app (ver docs/arquitectura.md).
// Tipado con el esquema generado: `npm run db:types` tras cada migración.
// En dev deshabilitamos el Web Lock de auth de supabase-js: con varias pestañas
// de localhost abiertas o un service worker viejo, el lock queda tomado y
// getSession()/signInWithPassword() cuelgan pendientes para siempre ("Buscando
// tu cuenta…" eterno). El no-op solo corre en local (import.meta.env.DEV); en
// prod se mantiene el lock por defecto (evita refresh simultáneo entre pestañas).
export const supabase = createClient<Database>(
	PUBLIC_SUPABASE_URL,
	PUBLIC_SUPABASE_ANON_KEY,
	import.meta.env.DEV ? { auth: { lock: async (_name, _acquireTimeout, fn) => fn() } } : undefined
);
