import { supabase } from '$lib/supabase';
import { dispositivoId } from './dispositivo';
import { obtenerUbicacion } from './geo';

export interface InsigniaNueva {
	id: string;
	nombre: string;
	copy: string;
}

export type RiegoResultado =
	| {
			ok: true;
			puntos: number;
			total_puntos: number | null;
			estado_anterior: string;
			insignias_nuevas: InsigniaNueva[];
	  }
	| {
			ok: false;
			motivo:
				| 'sin_autor'
				| 'arbol_inexistente'
				| 'sin_ubicacion'
				| 'lejos'
				| 'cooldown_arbol'
				| 'cooldown_vecino'
				| 'error_red';
			distancia_m?: number;
			proximo_riego?: string;
	  };

/** Registra el riego contra la RPC del servidor (la única puerta: BT-11). */
export async function registrarRiego(codigo: string): Promise<RiegoResultado> {
	const { lat, lng } = await obtenerUbicacion();
	const { data, error } = await supabase.rpc('registrar_riego', {
		p_codigo: codigo,
		p_dispositivo_id: dispositivoId(),
		p_lat: lat ?? undefined,
		p_lng: lng ?? undefined
	});
	if (error) return { ok: false, motivo: 'error_red' };
	return data as unknown as RiegoResultado;
}
