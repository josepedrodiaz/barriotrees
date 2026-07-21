// Sesión del vecino, compartida por toda la app.
// La sesión vive en el navegador (localStorage): las páginas leen datos
// públicos, y lo que necesita identidad son las RPC, que corren en el cliente
// con el token del vecino. Sin capa de servidor, sin cookies.

import { supabase } from '$lib/supabase';
import type { Session } from '@supabase/supabase-js';

export interface Perfil {
	id: string;
	nombre: string;
	puntos: number;
	es_admin: boolean;
	cambios_nombre: number;
}

export const sesion = $state({
	session: null as Session | null,
	perfil: null as Perfil | null,
	cargando: true
});

let iniciado = false;

/** Arranca el seguimiento de la sesión. Idempotente: se llama desde el layout. */
export function seguirSesion(): void {
	if (iniciado) return;
	iniciado = true;

	supabase.auth.getSession().then(({ data }) => {
		sesion.session = data.session;
		sesion.cargando = false;
		if (data.session) cargarPerfil();
	});

	supabase.auth.onAuthStateChange((_evento, s) => {
		sesion.session = s;
		sesion.cargando = false;
		if (s) cargarPerfil();
		else sesion.perfil = null;
	});
}

export async function cargarPerfil(): Promise<void> {
	const id = sesion.session?.user.id;
	if (!id) return;
	const { data } = await supabase
		.from('perfiles')
		.select('id, nombre, puntos, es_admin, cambios_nombre')
		.eq('id', id)
		.maybeSingle();
	sesion.perfil = data ?? null;
}

export async function salir(): Promise<void> {
	await supabase.auth.signOut();
	sesion.perfil = null;
}
