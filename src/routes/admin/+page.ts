import { supabase } from '$lib/supabase';

export const ssr = false;

export const load = async () => {
	const [{ data: arboles }, { data: especies }] = await Promise.all([
		supabase
			.from('arboles')
			.select('id, codigo, especie_id, nombre, sector, fecha_plantacion, lat, lng, activo')
			.order('codigo'),
		supabase.from('especies').select('id, nombre_comun, frecuencia_dias').order('nombre_comun')
	]);
	return { arboles: arboles ?? [], especies: especies ?? [] };
};
