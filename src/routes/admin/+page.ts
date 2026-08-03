import { supabase } from '$lib/supabase';

export const ssr = false;

export const load = async () => {
	const [{ data: arboles }, { data: especies }, { data: usuarios }] = await Promise.all([
		supabase
			.from('arboles')
			.select(
				'id, codigo, especie_id, nombre, sector, fecha_plantacion, lat, lng, frecuencia_dias_override, fecha_defuncion, causa_defuncion, activo'
			)
			.order('codigo'),
		supabase.from('especies').select('id, nombre_comun, frecuencia_dias').order('nombre_comun'),
		// Perfiles es de lectura pública: la lista de registrados para elegir
		// entregadores por nombre (el mail no sirve, nadie lo recuerda).
		supabase.from('perfiles').select('id, nombre, entregador').order('nombre')
	]);
	return { arboles: arboles ?? [], especies: especies ?? [], usuarios: usuarios ?? [] };
};
