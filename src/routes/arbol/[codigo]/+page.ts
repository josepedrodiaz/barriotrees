import { error } from '@sveltejs/kit';
import { supabase } from '$lib/supabase';

export const load = async ({ params }) => {
	const [{ data: arbol }, { data: duracion }] = await Promise.all([
		supabase.from('v_arboles_estado').select('*').eq('codigo', params.codigo).maybeSingle(),
		supabase.from('config').select('valor').eq('clave', 'duracion_riego_segundos').maybeSingle()
	]);
	if (!arbol) error(404, 'Ese árbol no existe. ¿El QR está bien?');
	return {
		arbol,
		duracionSegundos: Number(duracion?.valor ?? 20)
	};
};
