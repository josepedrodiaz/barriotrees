// Métricas agronómicas derivadas de los datos del juego (BT-41).
//
// El juego junta, sin querer, dos series temporales por árbol: los riegos
// (intervención humana, con fecha) y el clima diario (ET0 y lluvia). Con eso se
// reconstruye el balance hídrico día por día y salen las métricas que mira un
// ingeniero agrónomo: días de estrés, necesidad hídrica (ETc = Kc·ET0),
// supervivencia. Todo son funciones puras: la lógica del balance se reusa de
// balance-hidrico/estado, que ya están testeadas.

import { type Estado, type Bandas, BANDAS_DEFAULT, estadoSegunDias } from './estado';

/** Un día de clima con su fecha (YYYY-MM-DD). */
export interface DiaClima {
	fecha: string;
	et0: number;
	lluvia: number;
	tempMax?: number | null;
}

/** Un punto de la serie diaria de un árbol. */
export interface PuntoSerie {
	fecha: string;
	/** Déficit de agua acumulado ese día (mm). */
	deficit: number;
	/** Déficit en "días equivalentes de sed" (déficit / ET0 de referencia). */
	diasSed: number;
	estado: Estado;
	lluvia: number;
	huboRiego: boolean;
}

/**
 * Serie diaria de déficit y estado de un árbol, caminando día por día:
 * el día de un riego el suelo queda lleno (déficit 0); el resto de los días
 * sube con la ET0 y baja con la lluvia, con tope en 0 (el suelo se satura). Es
 * el mismo modelo que f_deficit_mm en Postgres, expandido a toda la ventana.
 */
export function serieDiaria(
	clima: DiaClima[],
	fechasRiego: Iterable<string>,
	f: number,
	et0Ref: number,
	bandas: Bandas = BANDAS_DEFAULT
): PuntoSerie[] {
	const riegos = new Set(fechasRiego);
	const serie: PuntoSerie[] = [];
	let saldo = 0;
	for (const dia of clima) {
		const huboRiego = riegos.has(dia.fecha);
		saldo = huboRiego ? 0 : Math.max(0, saldo + dia.et0 - dia.lluvia);
		const diasSed = et0Ref > 0 ? saldo / et0Ref : 0;
		serie.push({
			fecha: dia.fecha,
			deficit: Math.round(saldo * 10) / 10,
			diasSed,
			estado: estadoSegunDias(diasSed, f, bandas),
			lluvia: dia.lluvia,
			huboRiego
		});
	}
	return serie;
}

const SEDIENTOS: Estado[] = ['sediento', 'muy_sediento'];

/** Días que el árbol pasó con sed (sediento o muy sediento). */
export function diasDeEstres(serie: PuntoSerie[]): number {
	return serie.filter((p) => SEDIENTOS.includes(p.estado)).length;
}

/** Días en estado crítico (muy sediento). */
export function diasCriticos(serie: PuntoSerie[]): number {
	return serie.filter((p) => p.estado === 'muy_sediento').length;
}

/** Fracción del período en que el árbol estuvo bien atendido (feliz o bien). */
export function coberturaVerde(serie: PuntoSerie[]): number {
	if (!serie.length) return 0;
	const bien = serie.filter((p) => p.estado === 'feliz' || p.estado === 'bien').length;
	return bien / serie.length;
}

/** Necesidad hídrica del cultivo acumulada (mm): ETc = Kc · ET0 (FAO-56). */
export function etcAcumulada(clima: DiaClima[], kc: number): number {
	return redondear(clima.reduce((s, d) => s + d.et0 * kc, 0));
}

/** Evapotranspiración de referencia acumulada (mm). */
export function et0Acumulada(clima: DiaClima[]): number {
	return redondear(clima.reduce((s, d) => s + d.et0, 0));
}

/** Lluvia acumulada del período (mm). */
export function lluviaAcumulada(clima: DiaClima[]): number {
	return redondear(clima.reduce((s, d) => s + d.lluvia, 0));
}

/** Agua aplicada a mano, estimada (litros): un balde ≈ 10 L. */
export function aguaAplicadaLitros(cantidadRiegos: number, litrosPorBalde = 10): number {
	return cantidadRiegos * litrosPorBalde;
}

/** Intervalo real promedio entre riegos (días). Null si hubo menos de dos. */
export function frecuenciaRealDias(fechasRiego: string[]): number | null {
	if (fechasRiego.length < 2) return null;
	const orden = [...fechasRiego].sort();
	const primero = Date.parse(orden[0]);
	const ultimo = Date.parse(orden[orden.length - 1]);
	const dias = (ultimo - primero) / 86_400_000;
	return redondear(dias / (fechasRiego.length - 1), 1);
}

/** Tasa de supervivencia: vivos sobre total (0..1). */
export function tasaSupervivencia(vivos: number, total: number): number {
	return total > 0 ? vivos / total : 0;
}

function redondear(n: number, decimales = 1): number {
	const factor = 10 ** decimales;
	return Math.round(n * factor) / factor;
}
