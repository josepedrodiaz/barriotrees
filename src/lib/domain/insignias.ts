// La escalera de 7 insignias por puntos acumulados (decisión 20).
// La 1ª se gana con el primer riego y la 7ª casi nadie la alcanza: la
// dificultad crece exponencialmente. Los umbrales viven en la base y los edita
// la comisión, así que acá nada está hardcodeado — solo se calcula el avance.

export interface Escalon {
	id: string;
	orden: number;
	nombre: string;
	umbral_puntos: number;
}

export interface ProgresoEscalera {
	/** El último escalón alcanzado, o null si todavía no ganó ninguno. */
	actual: Escalon | null;
	/** El que viene, o null si ya llegó a lo más alto. */
	siguiente: Escalon | null;
	/** Puntos que faltan para el siguiente (0 si no hay siguiente). */
	faltan: number;
	/** Avance de 0 a 100 entre el escalón actual y el siguiente. */
	porcentaje: number;
}

export function progresoEscalera(puntos: number, escalones: Escalon[]): ProgresoEscalera {
	const orden = [...escalones].sort((a, b) => a.umbral_puntos - b.umbral_puntos);
	const alcanzados = orden.filter((e) => puntos >= e.umbral_puntos);
	const actual = alcanzados.at(-1) ?? null;
	const siguiente = orden.find((e) => puntos < e.umbral_puntos) ?? null;

	if (!siguiente) return { actual, siguiente: null, faltan: 0, porcentaje: 100 };

	const desde = actual?.umbral_puntos ?? 0;
	const tramo = siguiente.umbral_puntos - desde;
	const avance = puntos - desde;
	return {
		actual,
		siguiente,
		faltan: siguiente.umbral_puntos - puntos,
		porcentaje: tramo > 0 ? Math.min(100, Math.max(0, (avance / tramo) * 100)) : 0
	};
}

export function gano(ganadas: { insignia_id: string }[], id: string): boolean {
	return ganadas.some((g) => g.insignia_id === id);
}
