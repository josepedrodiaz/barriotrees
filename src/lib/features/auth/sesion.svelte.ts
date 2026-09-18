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
	entregador: boolean;
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

	// SOLO getSession define `cargando`: lee el token del localStorage y, si hay
	// sesión, espera también al perfil. Recién ahí sabemos el estado completo del
	// vecino y apagamos `cargando`. Antes, sin sesión + perfil todavía null, la
	// home mostraba un instante "sin cuenta" y saltaba.
	supabase.auth.getSession().then(async ({ data }) => {
		sesion.session = data.session;
		if (data.session) await cargarPerfil();
		sesion.cargando = false;
	});

	// Cambios en vivo (login/logout). NO toca `cargando`: al arrancar este evento
	// se dispara con session=null antes de que getSession resuelva, y apagar
	// `cargando` acá era lo que colaba el "sin cuenta". Tampoco usa async directo:
	// hacer await de otra llamada Supabase adentro del callback puede deadlockear.
	supabase.auth.onAuthStateChange((_evento, s) => {
		sesion.session = s;
		if (s) cargarPerfil();
		else sesion.perfil = null;
	});
}

export async function cargarPerfil(): Promise<void> {
	const id = sesion.session?.user.id;
	if (!id) return;
	const { data } = await supabase
		.from('perfiles')
		.select('id, nombre, puntos, es_admin, entregador, cambios_nombre')
		.eq('id', id)
		.maybeSingle();
	sesion.perfil = data ?? null;
}

export async function salir(): Promise<void> {
	await supabase.auth.signOut();
	sesion.perfil = null;
}
