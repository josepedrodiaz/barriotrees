import { describe, it, expect } from 'vitest';
import {
	serieDiaria,
	diasDeEstres,
	diasCriticos,
	coberturaVerde,
	etcAcumulada,
	et0Acumulada,
	lluviaAcumulada,
	aguaAplicadaLitros,
	frecuenciaRealDias,
	tasaSupervivencia,
	type DiaClima
} from './agronomia';

const ET0_REF = 4.5;
const F = 2;

// Clima seco de verano: cada día evapora ET0_REF, no llueve.
function seco(desde: number, n: number): DiaClima[] {
	return Array.from({ length: n }, (_, i) => ({
		fecha: `2026-01-${String(desde + i).padStart(2, '0')}`,
		et0: ET0_REF,
		lluvia: 0
	}));
}

describe('serieDiaria', () => {
	it('sin riego, en seco, acumula déficit y llega a muy sediento', () => {
		const serie = serieDiaria(seco(1, 6), [], F, ET0_REF);
		// día 1: 4.5mm = 1 día de sed -> feliz (<= F*0.5=1)
		expect(serie[0].estado).toBe('feliz');
		// día 3: 13.5mm = 3 días -> sediento (2 < 3 <= 4)
		expect(serie[2].estado).toBe('sediento');
		// día 5: 22.5mm = 5 días -> muy sediento (> 4)
		expect(serie[4].estado).toBe('muy_sediento');
	});

	it('el día del riego el suelo queda lleno (déficit 0)', () => {
		const serie = serieDiaria(seco(1, 5), ['2026-01-04'], F, ET0_REF);
		expect(serie[3].huboRiego).toBe(true);
		expect(serie[3].deficit).toBe(0);
		expect(serie[3].estado).toBe('feliz');
		// y al día siguiente vuelve a acumular desde cero
		expect(serie[4].deficit).toBeCloseTo(ET0_REF, 5);
	});

	it('la lluvia descuenta del déficit con tope en 0', () => {
		const clima: DiaClima[] = [
			{ fecha: '2026-01-01', et0: 4.5, lluvia: 0 },
			{ fecha: '2026-01-02', et0: 4.5, lluvia: 20 } // llueve fuerte
		];
		const serie = serieDiaria(clima, [], F, ET0_REF);
		expect(serie[0].deficit).toBe(4.5);
		expect(serie[1].deficit).toBe(0); // 4.5 + 4.5 - 20 -> tope en 0
	});
});

describe('métricas de estrés', () => {
	const serie = serieDiaria(seco(1, 6), [], F, ET0_REF);
	it('cuenta días de estrés (sediento + muy sediento)', () => {
		// días 3,4 sediento; 5,6 muy sediento = 4
		expect(diasDeEstres(serie)).toBe(4);
	});
	it('cuenta días críticos', () => {
		expect(diasCriticos(serie)).toBe(2);
	});
	it('cobertura verde es la fracción feliz/bien', () => {
		// días 1,2 en verde de 6 = 2/6
		expect(coberturaVerde(serie)).toBeCloseTo(2 / 6, 5);
	});
	it('cobertura de serie vacía es 0', () => {
		expect(coberturaVerde([])).toBe(0);
	});
});

describe('métricas de clima', () => {
	const clima: DiaClima[] = [
		{ fecha: '2026-01-01', et0: 4, lluvia: 2 },
		{ fecha: '2026-01-02', et0: 6, lluvia: 0 }
	];
	it('ET0 acumulada suma la evapotranspiración', () => {
		expect(et0Acumulada(clima)).toBe(10);
	});
	it('ETc aplica el Kc', () => {
		expect(etcAcumulada(clima, 0.7)).toBe(7); // 10 * 0.7
	});
	it('lluvia acumulada suma la lluvia', () => {
		expect(lluviaAcumulada(clima)).toBe(2);
	});
});

describe('riego y supervivencia', () => {
	it('agua aplicada estima por baldes', () => {
		expect(aguaAplicadaLitros(3)).toBe(30);
		expect(aguaAplicadaLitros(3, 8)).toBe(24);
	});
	it('frecuencia real es el intervalo promedio entre riegos', () => {
		// riegos con 4 días de span, 3 riegos -> 2 días de intervalo
		expect(frecuenciaRealDias(['2026-01-01', '2026-01-03', '2026-01-05'])).toBe(2);
	});
	it('frecuencia real es null con menos de dos riegos', () => {
		expect(frecuenciaRealDias(['2026-01-01'])).toBeNull();
		expect(frecuenciaRealDias([])).toBeNull();
	});
	it('tasa de supervivencia', () => {
		expect(tasaSupervivencia(8, 10)).toBe(0.8);
		expect(tasaSupervivencia(0, 0)).toBe(0);
	});
});
