import { supabase } from '$lib/supabase';
import { dispositivoId } from '$lib/features/riego/dispositivo';
import type { InsigniaNueva } from '$lib/features/riego/registrarRiego';

export type ReclamoResultado =
	| {
			ok: true;
			riegos: number;
			puntos: number;
			total_puntos?: number;
			insignias_nuevas: InsigniaNueva[];
	  }
	| { ok: false; motivo: 'sin_sesion' | 'sin_dispositivo' | 'error_red' };

/**
 * Adopta los riegos que este teléfono hizo sin cuenta (decisión 14).
 * Se llama apenas vuelve del login. Es seguro repetirlo: los riegos ya
 * reclamados no se vuelven a contar.
 */
export async function reclamarRiegos(): Promise<ReclamoResultado> {
	const { data, error } = await supabase.rpc('reclamar_riegos', {
		p_dispositivo_id: dispositivoId()
	});
	if (error) return { ok: false, motivo: 'error_red' };
	return data as unknown as ReclamoResultado;
}
