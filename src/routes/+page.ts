import { supabase } from '$lib/supabase';
import { urgencia } from '$lib/domain/estado';

// Home provisoria para navegar los árboles (la pantalla de alarmas real es BT-15).
export const load = async () => {
	const { data } = await supabase
		.from('v_arboles_estado')
		.select('codigo, nombre, sector, especie_nombre, dias_sin_riego, f_efectiva, estado, lat, lng');
	const arboles = (data ?? []).sort(
		(a, b) =>
			urgencia(b.dias_sin_riego, b.f_efectiva ?? 1) - urgencia(a.dias_sin_riego, a.f_efectiva ?? 1)
	);
	return { arboles };
};
