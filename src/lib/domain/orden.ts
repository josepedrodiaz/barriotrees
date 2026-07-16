// Orden de la pantalla inicial: a qué árbol conviene ir ahora.
//
// Criterio (decisión de producto, jul 2026): manda la NECESIDAD del árbol —
// primero los muy sedientos, después los sedientos, etc. La cercanía es el
// desempate: entre dos árboles igual de necesitados, va el que tenés al lado.
// Sin GPS, el desempate es la urgencia fina (días sin riego vs. F de la especie).

import { distanciaMetros } from './distancia';
import { urgencia, type Estado } from './estado';

/** Menor = más necesitado = más arriba en la lista. */
const SEVERIDAD: Record<Estado, number> = {
	muy_sediento: 0,
	sediento: 1,
	bien: 2,
	feliz: 3
};

export interface ArbolOrdenable {
	estado: string | null;
	dias_sin_riego: number | null;
	f_efectiva: number | null;
	lat: number | null;
	lng: number | null;
}

export interface Punto {
	lat: number;
	lng: number;
}

function severidad(estado: string | null): number {
	return SEVERIDAD[(estado ?? 'muy_sediento') as Estado] ?? 0;
}

/**
 * Ordena los árboles por necesidad y, dentro de cada estado, por cercanía.
 * Devuelve un array nuevo: pasarle el fix del GPS lo reordena en vivo.
 */
export function ordenarArboles<T extends ArbolOrdenable>(arboles: T[], desde: Punto | null): T[] {
	return [...arboles].sort((a, b) => {
		const sa = severidad(a.estado);
		const sb = severidad(b.estado);
		if (sa !== sb) return sa - sb;

		if (desde && a.lat != null && a.lng != null && b.lat != null && b.lng != null) {
			return (
				distanciaMetros(desde.lat, desde.lng, a.lat, a.lng) -
				distanciaMetros(desde.lat, desde.lng, b.lat, b.lng)
			);
		}

		return (
			urgencia(b.dias_sin_riego, b.f_efectiva ?? 1) - urgencia(a.dias_sin_riego, a.f_efectiva ?? 1)
		);
	});
}
