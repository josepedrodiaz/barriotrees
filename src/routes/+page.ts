import { supabase } from '$lib/supabase';
import { ordenarArboles } from '$lib/domain/orden';

// El orden final lo decide la página: se recalcula en vivo con la posición del
// vecino (ver ordenarArboles). Acá sale ya ordenado por necesidad para que el
// primer render, sin GPS todavía, no aparezca en orden arbitrario.
export const load = async () => {
	const [{ data: arboles }, { data: escalera }] = await Promise.all([
		supabase
			.from('v_arboles_estado')
			.select(
				'codigo, nombre, sector, especie_nombre, dias_sin_riego, f_efectiva, estado, lat, lng'
			),
		// Para saber en qué escalón está el vecino y cuánto le falta para el
		// siguiente, sin pedirle nada al servidor de más.
		supabase
			.from('insignias')
			.select('id, orden, nombre, umbral_puntos')
			.eq('tipo', 'escalera')
			.eq('activa', true)
			.order('orden')
	]);
	return {
		arboles: ordenarArboles(arboles ?? [], null),
		escalera: escalera ?? []
	};
};
