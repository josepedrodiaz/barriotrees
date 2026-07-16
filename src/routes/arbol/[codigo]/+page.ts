import { error } from '@sveltejs/kit';
import { supabase } from '$lib/supabase';

export const load = async ({ params }) => {
	const [{ data: arbol }, { data: config }] = await Promise.all([
		supabase.from('v_arboles_estado').select('*').eq('codigo', params.codigo).maybeSingle(),
		supabase.from('config').select('clave, valor')
	]);
	if (!arbol) error(404, 'Ese árbol no existe. ¿El QR está bien?');

	const c = Object.fromEntries((config ?? []).map((x) => [x.clave, x.valor]));
	return {
		arbol,
		duracionSegundos: Number(c['duracion_riego_segundos'] ?? 20),
		radioMetros: Number(c['radio_proximidad_metros'] ?? 50),
		// Para poder anunciar los puntos en el botón antes de regar. El servidor
		// es el que los otorga; esto es solo la zanahoria.
		puntosPorEstado: (c['puntos_riego'] ?? {}) as Record<string, number>
	};
};
