import { describe, expect, it } from 'vitest';
import { progresoEscalera, type Escalon } from './insignias';

// La escalera real sembrada en la base (docs/reglas-del-juego.md).
const ESCALERA: Escalon[] = [
	{ id: 'primer-riego', orden: 1, nombre: 'Primer Riego', umbral_puntos: 1 },
	{ id: 'aprendiz', orden: 2, nombre: 'Aprendiz', umbral_puntos: 100 },
	{ id: 'cuidador', orden: 3, nombre: 'Cuidador', umbral_puntos: 300 },
	{ id: 'gran-cuidador', orden: 4, nombre: 'Gran Cuidador', umbral_puntos: 800 },
	{ id: 'raiz-del-barrio', orden: 5, nombre: 'Raíz del Barrio', umbral_puntos: 2000 },
	{ id: 'alma-de-la-plaza', orden: 6, nombre: 'Alma de la Plaza', umbral_puntos: 4500 },
	{ id: 'gigante-del-oeste', orden: 7, nombre: 'Gigante del Oeste', umbral_puntos: 10000 }
];

describe('progresoEscalera', () => {
	it('vecino nuevo: sin escalón, apuntando al primero', () => {
		const p = progresoEscalera(0, ESCALERA);
		expect(p.actual).toBeNull();
		expect(p.siguiente?.id).toBe('primer-riego');
		expect(p.faltan).toBe(1);
	});

	it('el primer riego alcanza para el primer escalón (imposible no ganarlo)', () => {
		const p = progresoEscalera(1, ESCALERA);
		expect(p.actual?.id).toBe('primer-riego');
		expect(p.siguiente?.id).toBe('aprendiz');
		expect(p.faltan).toBe(99);
	});

	it('caso real de Pedro: 36 puntos, en camino a Aprendiz', () => {
		const p = progresoEscalera(36, ESCALERA);
		expect(p.actual?.id).toBe('primer-riego');
		expect(p.siguiente?.id).toBe('aprendiz');
		expect(p.faltan).toBe(64);
		// avanzó 35 de los 99 puntos que separan un escalón del otro
		expect(Math.round(p.porcentaje)).toBe(35);
	});

	it('justo en el umbral, el escalón se considera ganado', () => {
		const p = progresoEscalera(300, ESCALERA);
		expect(p.actual?.id).toBe('cuidador');
		expect(p.porcentaje).toBe(0);
	});

	it('el que llegó a lo más alto no tiene siguiente', () => {
		const p = progresoEscalera(10000, ESCALERA);
		expect(p.actual?.id).toBe('gigante-del-oeste');
		expect(p.siguiente).toBeNull();
		expect(p.faltan).toBe(0);
		expect(p.porcentaje).toBe(100);
	});

	it('no se rompe si la escalera viene desordenada', () => {
		const p = progresoEscalera(500, [...ESCALERA].reverse());
		expect(p.actual?.id).toBe('cuidador');
		expect(p.siguiente?.id).toBe('gran-cuidador');
	});

	it('la escalera puede crecer sin tocar el código', () => {
		const conOctavo = [
			...ESCALERA,
			{ id: 'leyenda', orden: 8, nombre: 'Leyenda', umbral_puntos: 25000 }
		];
		const p = progresoEscalera(10000, conOctavo);
		expect(p.actual?.id).toBe('gigante-del-oeste');
		expect(p.siguiente?.id).toBe('leyenda');
	});
});
