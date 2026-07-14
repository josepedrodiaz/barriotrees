import { describe, expect, it } from 'vitest';
import { estadoSegunDias, urgencia } from './estado';

// Casos de docs/especies-umbrales.md: jacarandá joven en verano, F=2.
describe('estadoSegunDias (F=2, jacarandá)', () => {
	it('nunca regado → muy sediento', () => {
		expect(estadoSegunDias(null, 2)).toBe('muy_sediento');
	});
	it('recién regado → feliz', () => {
		expect(estadoSegunDias(0, 2)).toBe('feliz');
	});
	it('hasta 0.5·F (1 día) → feliz', () => {
		expect(estadoSegunDias(1, 2)).toBe('feliz');
	});
	it('entre 0.5·F y F (2 días) → bien', () => {
		expect(estadoSegunDias(1.5, 2)).toBe('bien');
		expect(estadoSegunDias(2, 2)).toBe('bien');
	});
	it('entre F y 2·F (4 días) → sediento', () => {
		expect(estadoSegunDias(2.1, 2)).toBe('sediento');
		expect(estadoSegunDias(4, 2)).toBe('sediento');
	});
	it('más de 2·F → muy sediento (cuenta para Rescatista)', () => {
		expect(estadoSegunDias(4.1, 2)).toBe('muy_sediento');
	});
});

describe('estadoSegunDias respeta F por especie', () => {
	it('palmera (F=4) aguanta más que jacarandá (F=2)', () => {
		expect(estadoSegunDias(3, 4)).toBe('bien');
		expect(estadoSegunDias(3, 2)).toBe('sediento');
	});
});

describe('urgencia', () => {
	it('nunca regado es lo más urgente', () => {
		expect(urgencia(null, 2)).toBe(Infinity);
	});
	it('ordena por días relativos a F, no absolutos', () => {
		// 3 días sin riego: gravísimo para un jacarandá (F=2), casi nada para preexistencia (F=7)
		expect(urgencia(3, 2)).toBeGreaterThan(urgencia(3, 7));
	});
});
