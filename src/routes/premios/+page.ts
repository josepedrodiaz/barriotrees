import { supabase } from '$lib/supabase';

// El catálogo de pines es público (todos pueden ver qué hay para ganar). Lo del
// vecino —cuáles ganó y sus tokens de canje— lo suma la página con la RPC
// mis_canjes cuando hay sesión (los tokens son privados, no se leen de la tabla).
export const load = async () => {
	const [{ data: pines }, { data: config }] = await Promise.all([
		supabase
			.from('insignias')
			.select('id, nombre, orden, copy_desbloqueo')
			.eq('activa', true)
			.eq('es_pin', true)
			.order('orden', { ascending: true, nullsFirst: false }),
		supabase.from('config').select('valor').eq('clave', 'url_base').maybeSingle()
	]);
	return {
		pines: pines ?? [],
		urlBase: String(config?.valor ?? 'https://arboles-gigantes.vercel.app')
	};
};
