import { supabase } from '$lib/supabase';

export interface ArbolAdmin {
	id: string;
	codigo: string;
	especie_id: string;
	nombre: string | null;
	sector: string | null;
	fecha_plantacion: string | null;
	lat: number | null;
	lng: number | null;
	activo: boolean;
}

export type Guardado = { ok: true } | { ok: false; error: string };

/**
 * El alta y la edición pasan por PostgREST con la sesión del admin: la policy
 * admin_todo (BT-10) es la que decide de verdad. Si un vecino común abriera
 * esta pantalla, la vería pero no podría escribir nada.
 */
export async function guardarArbol(arbol: Partial<ArbolAdmin>): Promise<Guardado> {
	const codigo = arbol.codigo?.trim();
	if (!codigo) return { ok: false, error: 'El código no puede estar vacío.' };
	if (!/^[a-z0-9-]+$/.test(codigo)) {
		return {
			ok: false,
			error: 'El código va en minúsculas, sin espacios ni tildes (ej: jaca-11).'
		};
	}
	if (!arbol.especie_id) return { ok: false, error: 'Elegí una especie.' };

	const fila = {
		codigo,
		especie_id: arbol.especie_id,
		sector: arbol.sector?.trim() || null,
		fecha_plantacion: arbol.fecha_plantacion || null,
		lat: arbol.lat ?? null,
		lng: arbol.lng ?? null,
		activo: arbol.activo ?? true
	};

	const { error } = arbol.id
		? await supabase.from('arboles').update(fila).eq('id', arbol.id)
		: await supabase.from('arboles').insert(fila);

	if (!error) return { ok: true };
	if (error.code === '23505')
		return { ok: false, error: `Ya existe un árbol con el código ${fila.codigo}.` };
	if (error.code === '42501') return { ok: false, error: 'No tenés permisos de admin.' };
	return { ok: false, error: error.message };
}
