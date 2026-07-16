import { describe, expect, it } from 'vitest';
import { codigoDesdeQr } from './qr';

describe('codigoDesdeQr', () => {
	it('lee el código de la URL de una chapita', () => {
		expect(codigoDesdeQr('https://arboles-gigantes.vercel.app/arbol/jaca-05')).toBe('jaca-05');
	});

	it('aguanta query y hash que agrega el navegador', () => {
		expect(codigoDesdeQr('https://arboles-gigantes.vercel.app/arbol/jaca-05?x=1#y')).toBe(
			'jaca-05'
		);
	});

	it('sirve con dominio propio el día que lo haya', () => {
		expect(codigoDesdeQr('https://arbolesgigantes.com.ar/arbol/jaca-10/')).toBe('jaca-10');
	});

	it('acepta el código pelado (prueba o QR viejo)', () => {
		expect(codigoDesdeQr('jaca-03')).toBe('jaca-03');
		expect(codigoDesdeQr('  JACA-03  ')).toBe('jaca-03');
	});

	it('un QR que no es nuestro no devuelve nada', () => {
		expect(codigoDesdeQr('https://www.google.com')).toBeNull();
		expect(codigoDesdeQr('holaquetal esto no es un slug')).toBeNull();
		expect(codigoDesdeQr('')).toBeNull();
	});

	it('el árbol del QR manda aunque venga con basura alrededor', () => {
		expect(codigoDesdeQr('http://localhost:5173/arbol/jaca-07')).toBe('jaca-07');
	});
});
