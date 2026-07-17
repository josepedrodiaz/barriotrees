// Balance hídrico: la sed real del árbol según el clima (BT-33).
//
// La idea (ver el ticket BT-33): el estado de un árbol no es "días sin riego"
// —un reloj que asume que todos los días secan igual y que nunca llueve— sino
// cuánta agua le falta de verdad. Cada día el suelo pierde agua por
// evapotranspiración (ET0, en mm) y gana por lluvia (mm). La diferencia es el
// déficit.
//
// El truco elegante: el modelo viejo es este modelo con el supuesto "cada día
// evapora ET0_ref y no llueve". Por eso convertimos el déficit en mm a "días
// equivalentes" (déficit / ET0_ref) y lo pasamos por la MISMA lógica de bandas
// de estado.ts, que ya está testeada. La F de la especie (en días de verano)
// sigue mandando.

import { estadoSegunDias, type Bandas, BANDAS_DEFAULT, type Estado } from './estado';

export interface DiaClima {
	/** Evapotranspiración de referencia del día (mm). Lo que el clima "seca". */
	et0: number;
	/** Lluvia del día (mm). Lo que el clima "riega". */
	lluvia: number;
}

/**
 * Déficit de agua acumulado (mm) desde el último riego, día por día.
 *
 * Se acumula con tope en 0: un día de lluvia fuerte no "banca" crédito
 * infinito, porque el suelo se satura y el resto escurre. Recién regado el
 * saldo es 0; cada día sube con la ET0 y baja con la lluvia, sin pasar de 0
 * hacia abajo.
 */
export function deficitMm(dias: DiaClima[]): number {
	let saldo = 0;
	for (const d of dias) saldo = Math.max(0, saldo + d.et0 - d.lluvia);
	return saldo;
}

/**
 * Estado del árbol a partir del déficit real y la frecuencia F de la especie.
 * et0Ref = ET0 típica de verano; convierte F (días) en el déficit en mm que la
 * especie tolera, y sirve de fallback cuando falta el dato de un día.
 */
export function estadoSegunBalance(
	deficit: number,
	f: number,
	et0Ref: number,
	bandas: Bandas = BANDAS_DEFAULT
): Estado {
	// Días equivalentes de sed: reusa toda la lógica de bandas ya probada.
	return estadoSegunDias(deficit / et0Ref, f, bandas);
}
