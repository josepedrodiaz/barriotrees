// El último árbol cuya chapita se escaneó. Es lo que habilita a regar
// (decisión 17): sin escaneo reciente, el botón de riego no aparece, aunque el
// GPS diga que estás cerca. Los jacarandás están a ~5m entre sí y el GPS no los
// distingue: el escaneo es la única forma de saber a cuál estás regando.
//
// Vive en un store y no en la URL para que escanear en la home lleve al árbol
// ya reconocido. Dura poco: es "estoy acá ahora", no un permiso permanente.

const VALIDEZ_MS = 3 * 60 * 1000;

export const escaneo = $state({ codigo: null as string | null, ts: 0 });

export function registrarEscaneo(codigo: string): void {
	escaneo.codigo = codigo;
	escaneo.ts = Date.now();
}

/** ¿Se escaneó la chapita de este árbol hace poco? */
export function escaneadoReciente(codigo: string): boolean {
	return escaneo.codigo === codigo && Date.now() - escaneo.ts < VALIDEZ_MS;
}
