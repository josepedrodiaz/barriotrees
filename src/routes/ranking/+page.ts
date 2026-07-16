import { supabase } from '$lib/supabase';

// Público: el ranking se ve sin cuenta (es el gancho para sumarse). Se calcula
// al vuelo en la vista, sin cron (decisión 13).
export const load = async () => {
	const { data } = await supabase
		.from('v_ranking')
		.select('id, puesto, nombre, puntos, riegos')
		.order('puesto')
		.limit(50);
	return { ranking: data ?? [] };
};
