// Identidad anónima del teléfono: permite regar sin cuenta y reclamar esos
// riegos al registrarse (decisión 14: primero riega, después crea la cuenta).

const CLAVE = 'ag-dispositivo';

export function dispositivoId(): string {
	let id = localStorage.getItem(CLAVE);
	if (!id) {
		id = crypto.randomUUID();
		localStorage.setItem(CLAVE, id);
	}
	return id;
}
