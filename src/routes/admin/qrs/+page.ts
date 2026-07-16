import { supabase } from '$lib/supabase';

export const ssr = false;

export const load = async () => {
	const [{ data: arboles }, { data: url }] = await Promise.all([
		supabase
			.from('v_arboles_estado')
			.select('codigo, nombre, especie_nombre, sector')
			.order('codigo'),
		supabase.from('config').select('valor').eq('clave', 'url_base').maybeSingle()
	]);
	return {
		arboles: arboles ?? [],
		// La base manda: si mañana hay dominio propio, se cambia en config y las
		// chapitas nuevas salen bien sin tocar código.
		urlBase: String(url?.valor ?? 'https://arboles-gigantes.vercel.app')
	};
};
