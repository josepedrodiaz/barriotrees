import { supabase } from '$lib/supabase';
import { ordenarArboles } from '$lib/domain/orden';

// Home provisoria para navegar los árboles (la pantalla de alarmas real es BT-15).
// El orden final lo decide la página: se recalcula en vivo con la posición del
// vecino (ver ordenarArboles). Acá sale ya ordenado por necesidad para que el
// primer render, sin GPS todavía, no aparezca en orden arbitrario.
export const load = async () => {
	const { data } = await supabase
		.from('v_arboles_estado')
		.select('codigo, nombre, sector, especie_nombre, dias_sin_riego, f_efectiva, estado, lat, lng');
	return { arboles: ordenarArboles(data ?? [], null) };
};
