// Cuándo se muestra la bienvenida.
//
// (Se llama vista y no bienvenida.svelte.ts porque en macOS el sistema de
// archivos no distingue mayúsculas y chocaba con Bienvenida.svelte.)
//
// Pedido de Pedro (jul 2026): la ve TODO usuario no logueado. El que llega
// escaneando una chapita en la plaza no sabe qué es esto, y ese es el momento
// que decide si el proyecto lo engancha o no (decisión 14).
//
// Se recuerda en sessionStorage y no en localStorage a propósito: mientras el
// vecino no tenga cuenta, cada visita nueva se la muestra de nuevo (todavía no
// aprendió el juego), pero navegar entre pantallas no se la repite. Al crear
// la cuenta no la ve nunca más: ya sabe de qué se trata.

const CLAVE = 'ag-bienvenida-vista';

export const bienvenida = $state({ cerrada: false });

export function yaLaVio(): boolean {
	if (bienvenida.cerrada) return true;
	try {
		return sessionStorage.getItem(CLAVE) === '1';
	} catch {
		return false;
	}
}

export function cerrarBienvenida(): void {
	bienvenida.cerrada = true;
	try {
		sessionStorage.setItem(CLAVE, '1');
	} catch {
		// Navegador con almacenamiento bloqueado: se cierra igual por esta visita.
	}
}
