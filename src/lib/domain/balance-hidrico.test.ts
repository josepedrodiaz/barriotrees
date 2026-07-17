import { describe, expect, it } from 'vitest';
import { deficitMm, estadoSegunBalance, type DiaClima } from './balance-hidrico';

const ET0_REF = 4.5; // ET0 típica de verano en La Plata (mm/día)

// Sin datos de clima, el modelo tiene que comportarse igual que el reloj viejo:
// cada día seca ET0_ref y no llueve.
const seco = (n: number): DiaClima[] =>
	Array.from({ length: n }, () => ({ et0: ET0_REF, lluvia: 0 }));

describe('deficitMm', () => {
	it('recién regado (cero días) no tiene déficit', () => {
		expect(deficitMm([])).toBe(0);
	});

	it('acumula la evapotranspiración de los días secos', () => {
		expect(deficitMm(seco(3))).toBeCloseTo(13.5); // 3 × 4.5
	});

	it('la lluvia descuenta déficit', () => {
		// 3 días secando 4.5, con 5mm de lluvia el 2º día
		const dias: DiaClima[] = [
			{ et0: 4.5, lluvia: 0 },
			{ et0: 4.5, lluvia: 5 },
			{ et0: 4.5, lluvia: 0 }
		];
		expect(deficitMm(dias)).toBeCloseTo(8.5); // 4.5 + (4.5-5→tope 4) ... = 4.5 -0.5→0? no
	});

	it('una lluvia fuerte no banca crédito infinito (el suelo se satura)', () => {
		// Llueve 50mm y después 10 días secos de 4.5 = 45mm de sed
		const dias: DiaClima[] = [{ et0: 4.5, lluvia: 50 }, ...seco(10)];
		// Sin el tope daría 45-45.5 ≈ 0; con tope, la lluvia de más se pierde:
		// día 1 saldo=max(0, 4.5-50)=0; luego 10×4.5 = 45
		expect(deficitMm(dias)).toBeCloseTo(45);
	});

	it('el invierno seca menos: menos ET0 = menos déficit', () => {
		const invierno: DiaClima[] = Array.from({ length: 3 }, () => ({ et0: 1, lluvia: 0 }));
		expect(deficitMm(invierno)).toBeCloseTo(3); // vs 13.5 en verano
	});
});

describe('estadoSegunBalance', () => {
	// Jacarandá F=2. Umbrales en días → mm: feliz ≤1 día, bien ≤2, sediento ≤4.
	it('sin datos, reproduce el reloj viejo', () => {
		// 3 días secos = 13.5mm = 3 días equivalentes → sediento (como el reloj)
		expect(estadoSegunBalance(deficitMm(seco(3)), 2, ET0_REF)).toBe('sediento');
		expect(estadoSegunBalance(deficitMm(seco(1)), 2, ET0_REF)).toBe('feliz');
		expect(estadoSegunBalance(deficitMm(seco(5)), 2, ET0_REF)).toBe('muy_sediento');
	});

	it('si llovió, un árbol "de 3 días" no tiene sed', () => {
		// 3 días, pero llovió 20mm ayer: déficit real bajo → feliz, no sediento
		const dias: DiaClima[] = [
			{ et0: 4.5, lluvia: 0 },
			{ et0: 4.5, lluvia: 20 },
			{ et0: 4.5, lluvia: 0 }
		];
		expect(deficitMm(dias)).toBeCloseTo(4.5);
		expect(estadoSegunBalance(deficitMm(dias), 2, ET0_REF)).toBe('feliz');
	});

	it('el calor extremo apura la sed: mismos días, más déficit', () => {
		// 2 días de ola de calor (ET0 8) secan más que 2 normales
		const calor: DiaClima[] = [
			{ et0: 8, lluvia: 0 },
			{ et0: 8, lluvia: 0 }
		];
		// 16mm ≈ 3.5 días equivalentes → sediento, aunque pasaron solo 2 días
		expect(estadoSegunBalance(deficitMm(calor), 2, ET0_REF)).toBe('sediento');
		expect(estadoSegunBalance(deficitMm(seco(2)), 2, ET0_REF)).toBe('bien');
	});
});
