// Qué código de árbol trae un QR escaneado. Las chapitas llevan la URL del
// árbol (BT-19), pero el lector puede devolver la URL entera, con query o
// hash, o —en pruebas— el código pelado. Todo eso se reduce al código.

/** Extrae el código de árbol de lo que devolvió el escáner, o null si no es un QR nuestro. */
export function codigoDesdeQr(texto: string): string | null {
	const t = texto.trim();

	// Forma canónica: .../arbol/<codigo> (con o sin dominio, query o hash).
	const enRuta = t.match(/\/arbol\/([a-z0-9-]+)/i);
	if (enRuta) return enRuta[1].toLowerCase();

	// Código pelado (un QR viejo o una prueba): solo si tiene forma de slug.
	if (/^[a-z0-9-]{2,40}$/i.test(t)) return t.toLowerCase();

	return null;
}
