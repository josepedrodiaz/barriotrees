import { supabase } from '$lib/supabase';

export const ssr = false;

type Raw = {
	id: string;
	tipo: string;
	descripcion: string | null;
	creado_en: string;
	arbol:
		| { codigo: string | null; nombre: string | null }
		| { codigo: string | null; nombre: string | null }[]
		| null;
	autor: { nombre: string | null } | { nombre: string | null }[] | null;
};

export const load = async () => {
	const [{ data: arboles }, { data: especies }, { data: usuarios }, { data: reportes }] =
		await Promise.all([
			supabase
				.from('arboles')
				.select(
					'id, codigo, especie_id, nombre, sector, fecha_plantacion, lat, lng, frecuencia_dias_override, fecha_defuncion, causa_defuncion, activo'
				)
				.order('codigo'),
			supabase.from('especies').select('id, nombre_comun, frecuencia_dias').order('nombre_comun'),
			// Perfiles es de lectura pública: la lista de registrados para elegir
			// entregadores por nombre (el mail no sirve, nadie lo recuerda).
			supabase.from('perfiles').select('id, nombre, entregador').order('nombre'),
			// Reportes de peligro pendientes de revisar, más viejo primero.
			supabase
				.from('reportes')
				.select(
					'id, tipo, descripcion, creado_en, arbol:arboles(codigo, nombre), autor:perfiles(nombre)'
				)
				.eq('estado', 'pendiente')
				.order('creado_en', { ascending: true })
		]);

	// Aplanamos el embed (arbol/autor vienen anidados) para que el template no
	// tenga que lidiar con el tipado a-uno de Supabase.
	const uno = <T>(x: T | T[] | null): T | null => (Array.isArray(x) ? (x[0] ?? null) : x);
	const reportesPlano = ((reportes ?? []) as unknown as Raw[]).map((r) => ({
		id: r.id,
		tipo: r.tipo,
		descripcion: r.descripcion,
		creado_en: r.creado_en,
		codigo: uno(r.arbol)?.codigo ?? null,
		arbolNombre: uno(r.arbol)?.nombre ?? null,
		autor: uno(r.autor)?.nombre ?? null
	}));

	return {
		arboles: arboles ?? [],
		especies: especies ?? [],
		usuarios: usuarios ?? [],
		reportes: reportesPlano
	};
};
