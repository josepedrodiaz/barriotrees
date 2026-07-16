import { describe, expect, it } from 'vitest';
import { ordenarArboles, type ArbolOrdenable } from './orden';

// Coordenadas reales del relevamiento (docs/relevamiento-jacarandas.json).
const JACA_01 = { lat: -34.97879264721342, lng: -58.02040327572772 };
const JACA_10 = { lat: -34.97864185621449, lng: -58.020219814115144 };

const arbol = (o: Partial<ArbolOrdenable> & { codigo: string }) => ({
	estado: 'sediento',
	dias_sin_riego: 3,
	f_efectiva: 2,
	lat: null,
	lng: null,
	...o
});

describe('ordenarArboles: manda la necesidad', () => {
	it('los muy sedientos van arriba, aunque estén más lejos', () => {
		const lista = [
			arbol({ codigo: 'feliz-al-lado', estado: 'feliz', ...JACA_01 }),
			arbol({ codigo: 'critico-lejos', estado: 'muy_sediento', ...JACA_10 })
		];
		// Parado justo en jaca-01
		const orden = ordenarArboles(lista, JACA_01).map((a) => a.codigo);
		expect(orden).toEqual(['critico-lejos', 'feliz-al-lado']);
	});

	it('respeta el escalafón completo de estados', () => {
		const lista = [
			arbol({ codigo: 'd', estado: 'feliz' }),
			arbol({ codigo: 'b', estado: 'sediento' }),
			arbol({ codigo: 'a', estado: 'muy_sediento' }),
			arbol({ codigo: 'c', estado: 'bien' })
		];
		expect(ordenarArboles(lista, null).map((a) => a.codigo)).toEqual(['a', 'b', 'c', 'd']);
	});
});

describe('ordenarArboles: la cercanía desempata', () => {
	it('entre dos igual de sedientos, primero el que tenés al lado', () => {
		const lista = [
			arbol({ codigo: 'lejos', estado: 'muy_sediento', ...JACA_10 }),
			arbol({ codigo: 'cerca', estado: 'muy_sediento', ...JACA_01 })
		];
		expect(ordenarArboles(lista, JACA_01).map((a) => a.codigo)).toEqual(['cerca', 'lejos']);
	});

	it('se reordena si el vecino se mueve al otro extremo', () => {
		const lista = [
			arbol({ codigo: 'jaca-01', estado: 'muy_sediento', ...JACA_01 }),
			arbol({ codigo: 'jaca-10', estado: 'muy_sediento', ...JACA_10 })
		];
		expect(ordenarArboles(lista, JACA_01)[0].codigo).toBe('jaca-01');
		expect(ordenarArboles(lista, JACA_10)[0].codigo).toBe('jaca-10');
	});

	it('sin GPS, desempata la urgencia fina (días vs. F de la especie)', () => {
		const lista = [
			// misma banda de estado, pero uno la pasó peor respecto de su especie
			arbol({ codigo: 'menos-urgente', estado: 'sediento', dias_sin_riego: 3, f_efectiva: 3 }),
			arbol({ codigo: 'mas-urgente', estado: 'sediento', dias_sin_riego: 3.9, f_efectiva: 2 })
		];
		expect(ordenarArboles(lista, null).map((a) => a.codigo)).toEqual([
			'mas-urgente',
			'menos-urgente'
		]);
	});

	it('un árbol sin coordenadas no rompe el orden', () => {
		const lista = [
			arbol({ codigo: 'sin-coords', estado: 'muy_sediento' }),
			arbol({ codigo: 'con-coords', estado: 'muy_sediento', ...JACA_01 })
		];
		expect(ordenarArboles(lista, JACA_01)).toHaveLength(2);
	});
});

describe('ordenarArboles: no muta', () => {
	it('devuelve un array nuevo y deja el original intacto', () => {
		const lista = [
			arbol({ codigo: 'b', estado: 'feliz' }),
			arbol({ codigo: 'a', estado: 'muy_sediento' })
		];
		const orden = ordenarArboles(lista, null);
		expect(orden).not.toBe(lista);
		expect(lista.map((a) => a.codigo)).toEqual(['b', 'a']);
	});
});
