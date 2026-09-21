import { supabase } from '$lib/supabase';
import { sesion } from '$lib/features/auth/sesion.svelte';

export type TipoReporte = 'hormigas' | 'plaga' | 'rama_rota' | 'vandalismo' | 'otro';

/** Los tipos que ofrece el enum tipo_reporte, con su cara para el vecino. */
export const TIPOS_REPORTE: { valor: TipoReporte; etiqueta: string; emoji: string }[] = [
	{ valor: 'hormigas', etiqueta: 'Hormigas', emoji: '🐜' },
	{ valor: 'plaga', etiqueta: 'Plaga o bicho', emoji: '🐛' },
	{ valor: 'rama_rota', etiqueta: 'Rama rota o caída', emoji: '🪵' },
	{ valor: 'vandalismo', etiqueta: 'Daño o vandalismo', emoji: '💔' },
	{ valor: 'otro', etiqueta: 'Otra cosa', emoji: '❓' }
];

export type ReporteResultado = { ok: true } | { ok: false; motivo: 'sin_cuenta' | 'error_red' };

/**
 * Reporta un problema en un árbol. El insert va directo (policy `reportar`):
 * queda pendiente y sin puntos hasta que el admin lo verifique. Necesita cuenta:
 * un reporte anónimo no se puede premiar ni seguir.
 */
export async function reportarPeligro(
	arbolId: string,
	tipo: TipoReporte,
	descripcion: string
): Promise<ReporteResultado> {
	const perfilId = sesion.perfil?.id;
	if (!perfilId) return { ok: false, motivo: 'sin_cuenta' };

	const { error } = await supabase.from('reportes').insert({
		arbol_id: arbolId,
		perfil_id: perfilId,
		tipo,
		descripcion: descripcion.trim() || null
	});
	if (error) return { ok: false, motivo: 'error_red' };
	return { ok: true };
}
