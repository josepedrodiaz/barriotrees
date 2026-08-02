import { supabase } from '$lib/supabase';

export const ssr = false;

interface Entregador {
	id: string;
	nombre: string;
	email: string;
}

export const load = async () => {
	const [{ data: arboles }, { data: especies }, { data: entregadoresRes }] = await Promise.all([
		supabase
			.from('arboles')
			.select('id, codigo, especie_id, nombre, sector, fecha_plantacion, lat, lng, activo')
			.order('codigo'),
		supabase.from('especies').select('id, nombre_comun, frecuencia_dias').order('nombre_comun'),
		supabase.rpc('listar_entregadores')
	]);
	const er = entregadoresRes as { ok?: boolean; entregadores?: Entregador[] } | null;
	return {
		arboles: arboles ?? [],
		especies: especies ?? [],
		entregadores: er?.ok ? (er.entregadores ?? []) : []
	};
};
