// Reglas de estado del árbol — espejo exacto de f_estado_arbol en Postgres.
// El servidor es la autoridad (los puntos salen de ahí); esto existe para que
// la UI pueda mostrar y ordenar sin ida y vuelta.

export type Estado = 'feliz' | 'bien' | 'sediento' | 'muy_sediento';

export interface Bandas {
	feliz: number;
	bien: number;
	sediento: number;
}

export const BANDAS_DEFAULT: Bandas = { feliz: 0.5, bien: 1, sediento: 2 };

/** Estado según días sin riego vs. frecuencia objetivo F de la especie. */
export function estadoSegunDias(
	diasSinRiego: number | null,
	f: number,
	bandas: Bandas = BANDAS_DEFAULT
): Estado {
	if (diasSinRiego === null) return 'muy_sediento';
	if (diasSinRiego <= f * bandas.feliz) return 'feliz';
	if (diasSinRiego <= f * bandas.bien) return 'bien';
	if (diasSinRiego <= f * bandas.sediento) return 'sediento';
	return 'muy_sediento';
}

/** Para ordenar la pantalla inicial: más urgente primero. */
export function urgencia(diasSinRiego: number | null, f: number): number {
	if (diasSinRiego === null) return Infinity;
	return diasSinRiego / f;
}

export const ESTADO_INFO: Record<Estado, { etiqueta: string; emoji: string; clase: string }> = {
	feliz: { etiqueta: 'Feliz', emoji: '🌳', clase: 'estado-feliz' },
	bien: { etiqueta: 'Bien', emoji: '🌿', clase: 'estado-bien' },
	sediento: { etiqueta: 'Sediento', emoji: '💧', clase: 'estado-sediento' },
	muy_sediento: { etiqueta: '¡Muy sediento!', emoji: '🆘', clase: 'estado-muy-sediento' }
};
