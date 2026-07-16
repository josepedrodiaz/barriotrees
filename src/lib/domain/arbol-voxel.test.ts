import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
	bloquesArbol,
	bloquesSegunEstado,
	SALUD,
	sombra,
	proyectar,
	ANCHO,
	ALTO,
	VERTICAL,
	VIEW_BOX
} from './arbol-voxel';

const FLOR = 'rgb(124,92,208)';
const flores = (b: ReturnType<typeof bloquesArbol>) => b.filter((x) => x.cara === FLOR);
const hojas = (b: ReturnType<typeof bloquesArbol>) => b.filter((x) => x.z >= 3 && x.cara !== FLOR);
const verde = (color: string) => {
	const [r, , v] = color.match(/\d+/g)!.map(Number);
	return v - r; // cuánto le gana el verde al rojo: negativo = marrón, positivo = verde
};

describe('el árbol crece con la salud', () => {
	it('un árbol al borde de la muerte tiene el follaje mínimo', () => {
		const b = bloquesArbol(SALUD.muy_sediento);
		expect(hojas(b)).toHaveLength(5);
		expect(flores(b)).toHaveLength(0);
	});

	it('sediento todavía no gana follaje', () => {
		expect(hojas(bloquesArbol(SALUD.sediento))).toHaveLength(5);
	});

	it('cuando está bien le crecen las hojas de los costados y la copa', () => {
		expect(hojas(bloquesArbol(SALUD.bien))).toHaveLength(10);
		expect(flores(bloquesArbol(SALUD.bien))).toHaveLength(0);
	});

	it('solo el árbol feliz florece: son jacarandás', () => {
		const b = bloquesArbol(SALUD.feliz);
		expect(hojas(b)).toHaveLength(10);
		expect(flores(b)).toHaveLength(3);
	});

	it('el follaje crece de forma monótona: regar nunca empeora la vista', () => {
		const cantidad = (s: number) => hojas(bloquesArbol(s)).length + flores(bloquesArbol(s)).length;
		for (let s = 0; s <= 1; s += 0.05) {
			expect(cantidad(s)).toBeGreaterThanOrEqual(cantidad(s - 0.05));
		}
	});
});

describe('el color de las hojas cuenta la sed', () => {
	it('el árbol muy sediento tiene hojas marrones y el feliz, verdes', () => {
		expect(verde(hojas(bloquesArbol(SALUD.muy_sediento))[0].cara)).toBeLessThan(0);
		expect(verde(hojas(bloquesArbol(SALUD.feliz))[0].cara)).toBeGreaterThan(0);
	});

	it('cuanto más sano, más verde', () => {
		const c = (s: number) => verde(hojas(bloquesArbol(s))[0].cara);
		expect(c(SALUD.muy_sediento)).toBeLessThan(c(SALUD.sediento));
		expect(c(SALUD.sediento)).toBeLessThan(c(SALUD.bien));
		expect(c(SALUD.bien)).toBeLessThan(c(SALUD.feliz));
	});
});

describe('estructura', () => {
	it('siempre tiene piso y tronco', () => {
		for (const estado of ['feliz', 'bien', 'sediento', 'muy_sediento'] as const) {
			const b = bloquesSegunEstado(estado);
			expect(b.filter((x) => x.z <= 2)).toHaveLength(3);
		}
	});

	it('se dibuja de atrás hacia adelante o el tronco taparía la copa', () => {
		const b = bloquesArbol(1);
		for (let i = 1; i < b.length; i++) {
			const prof = b[i].x + b[i].y - (b[i - 1].x + b[i - 1].y);
			expect(prof >= 0).toBe(true);
			if (prof === 0) expect(b[i].z).toBeGreaterThanOrEqual(b[i - 1].z);
		}
	});

	it('la salud se recorta: nadie explota con valores raros', () => {
		expect(bloquesArbol(-5)).toEqual(bloquesArbol(0));
		expect(bloquesArbol(99)).toEqual(bloquesArbol(1));
	});

	// `sombra` oscurece leyendo los números del color: con un hexadecimal
	// tomaría los dígitos sueltos de '#6BBE4A' como canales y devolvería
	// cualquier cosa. Todos los colores tienen que salir ya en rgb().
	it('todos los colores salen en rgb() para que la sombra funcione', () => {
		for (const b of bloquesArbol(1)) {
			expect(b.cara).toMatch(/^rgb\(\d+,\d+,\d+\)$/);
			expect(b.lado).toMatch(/^rgb\(\d+,\d+,\d+\)$/);
			expect(sombra(b.lado, 0.5)).toMatch(/^rgb\(\d+,\d+,\d+\)$/);
		}
	});
});

// La decisión 21 dice que el estilo final es IGUAL al de la demo, así que la
// demo no es inspiración: es la referencia. Este test corre la isoTree
// original de tools/demo.html y exige que nuestro SVG salga idéntico. Si
// alguien toca la geometría, los colores o el orden de dibujo, se entera acá.
describe('fidelidad con la demo (tools/demo.html)', () => {
	const html = readFileSync(new URL('../../../tools/demo.html', import.meta.url), 'utf8');
	const original = html.slice(
		html.indexOf('function lerpHex'),
		html.indexOf('function renderHome')
	);
	const isoTreeDemo = new Function(`${original}; return isoTree;`)() as (
		h: number,
		px: number
	) => string;

	function nuestroSvg(salud: number, px: number): string {
		let out = '';
		for (const b of bloquesArbol(salud)) {
			const { cx, cy } = proyectar(b);
			out +=
				`<path d="M${cx} ${cy - ALTO} L${cx + ANCHO} ${cy} L${cx} ${cy + ALTO} L${cx - ANCHO} ${cy} Z" fill="${b.cara}"/>` +
				`<path d="M${cx - ANCHO} ${cy} L${cx} ${cy + ALTO} L${cx} ${cy + ALTO + VERTICAL} L${cx - ANCHO} ${cy + VERTICAL} Z" fill="${sombra(b.lado, 0.72)}"/>` +
				`<path d="M${cx + ANCHO} ${cy} L${cx} ${cy + ALTO} L${cx} ${cy + ALTO + VERTICAL} L${cx + ANCHO} ${cy + VERTICAL} Z" fill="${sombra(b.lado, 0.52)}"/>`;
		}
		return `<svg viewBox="${VIEW_BOX}" width="${px}" height="${px}" xmlns="http://www.w3.org/2000/svg">${out}</svg>`;
	}

	it.each([0, SALUD.muy_sediento, SALUD.sediento, 0.5, 0.6, SALUD.bien, 0.82, 0.9, SALUD.feliz])(
		'con salud %s el árbol sale igual que en la demo',
		(salud) => {
			expect(nuestroSvg(salud, 120)).toBe(isoTreeDemo(salud, 120));
		}
	);
});

describe('proyección isométrica', () => {
	it('subir un bloque lo dibuja más arriba en la pantalla', () => {
		expect(proyectar({ x: 0, y: 0, z: 1, cara: '', lado: '' }).cy).toBeLessThan(
			proyectar({ x: 0, y: 0, z: 0, cara: '', lado: '' }).cy
		);
	});

	it('la sombra oscurece', () => {
		expect(sombra('rgb(100,100,100)', 0.5)).toBe('rgb(50,50,50)');
	});
});
