// El árbol voxel isométrico: la identidad visual del juego (decisión 21).
// Portado de `isoTree` en tools/demo.html, que es lo que aprobó la comisión.
//
// No hay imágenes: el árbol se genera a partir de su salud (0..1). A medida
// que lo riegan, las hojas pasan de marrón a verde, le crecen bloques de
// follaje y, si llega a estar feliz, le brotan flores violetas de jacarandá.
// Es la decisión 3 hecha código — y nunca dice que al árbol "le salió una
// rama": es una representación, no una promesa sobre el árbol real.

import type { Estado } from './estado';

/** Cuán sano se ve el árbol en cada estado (los valores de la demo). */
export const SALUD: Record<Estado, number> = {
	feliz: 1,
	bien: 0.68,
	sediento: 0.42,
	muy_sediento: 0.16
};

const PASTO = '#6BBE4A';
const TIERRA = '#7A4F2A';
const TRONCO = '#6E4326';
const FLOR = '#7C5CD0';
const HOJA_SECA = '#B5772E';
const HOJA_VIVA = '#3FA34D';

/** Umbrales de salud a los que el árbol gana follaje o florece. */
const FOLLAJE_MEDIO = 0.5;
const FOLLAJE_ALTO = 0.6;
const FLORECE = 0.82;

export interface Bloque {
	x: number;
	y: number;
	z: number;
	/** Color de la cara de arriba. */
	cara: string;
	/** Color de los laterales (la tierra tiene distinto que el pasto). */
	lado: string;
}

const canal = (hex: string, i: number) => parseInt(hex.slice(1 + i * 2, 3 + i * 2), 16);

/**
 * Todo color sale de acá en formato rgb(): `sombra` lee números, y un
 * hexadecimal la haría leer los dígitos sueltos de '#6BBE4A' como si fueran
 * canales.
 */
function aRgb(hex: string): string {
	return `rgb(${canal(hex, 0)},${canal(hex, 1)},${canal(hex, 2)})`;
}

function mezclar(desde: string, hasta: string, t: number): string {
	const rgb = [0, 1, 2].map((i) => {
		const a = canal(desde, i);
		const b = canal(hasta, i);
		return Math.round(a + (b - a) * t);
	});
	return `rgb(${rgb[0]},${rgb[1]},${rgb[2]})`;
}

/**
 * Los bloques del árbol, ya ordenados para dibujarlos de atrás hacia adelante
 * (el que pinta último tapa: sin esto el follaje quedaría detrás del tronco).
 */
export function bloquesArbol(salud: number): Bloque[] {
	const s = Math.min(1, Math.max(0, salud));
	const hoja = mezclar(HOJA_SECA, HOJA_VIVA, s);
	const bloques: Bloque[] = [
		{ x: 0, y: 0, z: 0, cara: aRgb(PASTO), lado: aRgb(TIERRA) },
		{ x: 0, y: 0, z: 1, cara: aRgb(TRONCO), lado: aRgb(TRONCO) },
		{ x: 0, y: 0, z: 2, cara: aRgb(TRONCO), lado: aRgb(TRONCO) }
	];

	const follaje: [number, number, number][] = [
		[0, 0, 3],
		[1, 0, 3],
		[-1, 0, 3],
		[0, 1, 3],
		[0, -1, 3]
	];
	if (s > FOLLAJE_MEDIO) follaje.push([1, 1, 3], [-1, -1, 3], [1, -1, 3], [-1, 1, 3]);
	if (s > FOLLAJE_ALTO) follaje.push([0, 0, 4]);
	for (const [x, y, z] of follaje) bloques.push({ x, y, z, cara: hoja, lado: hoja });

	if (s > FLORECE) {
		for (const [x, y, z] of [
			[0, 0, 5],
			[1, 0, 4],
			[-1, 0, 4]
		]) {
			bloques.push({ x, y, z, cara: aRgb(FLOR), lado: aRgb(FLOR) });
		}
	}

	return bloques.sort((a, b) => a.x + a.y - (b.x + b.y) || a.z - b.z);
}

export function bloquesSegunEstado(estado: Estado): Bloque[] {
	return bloquesArbol(SALUD[estado]);
}

/** Oscurece un color para las caras laterales (da el volumen del cubo). */
export function sombra(color: string, factor: number): string {
	const n = color.match(/\d+/g);
	if (!n) return color;
	return `rgb(${n.map((v) => Math.round(Number(v) * factor)).join(',')})`;
}

/** Proyección isométrica: de coordenadas de bloque a píxeles del SVG. */
export const LADO = 12;
export const ANCHO = LADO;
export const ALTO = LADO / 2;
export const VERTICAL = LADO;
export const ORIGEN_X = 50;
export const ORIGEN_Y = 58;
export const VIEW_BOX = '0 -14 100 114';

export function proyectar(b: Bloque): { cx: number; cy: number } {
	return {
		cx: ORIGEN_X + (b.x - b.y) * ANCHO,
		cy: ORIGEN_Y + (b.x + b.y) * ALTO - b.z * VERTICAL
	};
}
