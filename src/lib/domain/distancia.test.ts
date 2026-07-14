import { describe, expect, it } from 'vitest';
import { distanciaMetros, formatearDistancia } from './distancia';

// Puntos reales del relevamiento (docs/relevamiento-jacarandas.json).
const JACA_09 = { lat: -34.97867548281069, lng: -58.02017497281731 };
const JACA_10 = { lat: -34.97864185621449, lng: -58.020219814115144 };
const OBELISCO = { lat: -34.6037, lng: -58.3816 };

describe('distanciaMetros', () => {
	it('mismo punto → 0', () => {
		expect(distanciaMetros(JACA_09.lat, JACA_09.lng, JACA_09.lat, JACA_09.lng)).toBe(0);
	});

	it('dos jacarandás vecinos de la galería están a pocos metros', () => {
		const d = distanciaMetros(JACA_09.lat, JACA_09.lng, JACA_10.lat, JACA_10.lng);
		expect(d).toBeGreaterThan(3);
		expect(d).toBeLessThan(15);
	});

	it('coincide con el servidor: plaza → Obelisco ≈ 53.177 m (lo que devolvió la RPC)', () => {
		const d = distanciaMetros(JACA_09.lat, JACA_09.lng, OBELISCO.lat, OBELISCO.lng);
		expect(Math.round(d)).toBeGreaterThan(52000);
		expect(Math.round(d)).toBeLessThan(54000);
	});

	it('es simétrica', () => {
		expect(distanciaMetros(JACA_09.lat, JACA_09.lng, OBELISCO.lat, OBELISCO.lng)).toBeCloseTo(
			distanciaMetros(OBELISCO.lat, OBELISCO.lng, JACA_09.lat, JACA_09.lng)
		);
	});
});

describe('formatearDistancia', () => {
	it('metros redondeados hasta el kilómetro', () => {
		expect(formatearDistancia(7.6)).toBe('8 m');
		expect(formatearDistancia(340)).toBe('340 m');
		expect(formatearDistancia(999.4)).toBe('999 m');
	});
	it('kilómetros con una decimal a partir de 1000 m', () => {
		expect(formatearDistancia(1000)).toBe('1 km');
		expect(formatearDistancia(1240)).toBe('1,2 km');
		expect(formatearDistancia(53177)).toBe('53,2 km');
	});
});
