// Posición del vecino en tiempo real, compartida por toda la app.
// Investigado (jul 2026): para una PWA, la Geolocation API del navegador es la
// única fuente gratuita con precisión GPS (~5-30 m en exteriores); las
// alternativas por IP tienen precisión de ciudad y no sirven para esto.
// watchPosition > getCurrentPosition: el navegador empuja cada cambio, el GPS
// queda "caliente" para el momento del riego, y trae la precisión en metros.

export interface Fix {
	lat: number;
	lng: number;
	precision: number; // metros (radio de error que reporta el GPS)
	ts: number;
}

const CLAVE_OPTIN = 'ag-distancias';
let watchId: number | null = null;

export const gps = $state({
	fix: null as Fix | null,
	siguiendo: false,
	error: null as 'permiso' | 'sin_senal' | null
});

/** Empieza a seguir la posición (dispara el pedido de permiso la primera vez). */
export function seguirPosicion(): void {
	if (watchId !== null || !('geolocation' in navigator)) return;
	gps.siguiendo = true;
	gps.error = null;
	localStorage.setItem(CLAVE_OPTIN, '1');
	watchId = navigator.geolocation.watchPosition(
		(pos) => {
			gps.fix = {
				lat: pos.coords.latitude,
				lng: pos.coords.longitude,
				precision: pos.coords.accuracy,
				ts: Date.now()
			};
			gps.error = null;
		},
		(e) => {
			if (e.code === e.PERMISSION_DENIED) {
				gps.error = 'permiso';
				gps.siguiendo = false;
				if (watchId !== null) navigator.geolocation.clearWatch(watchId);
				watchId = null;
				localStorage.removeItem(CLAVE_OPTIN);
			} else if (!gps.fix) {
				// Timeout o sin señal: el watch sigue vivo, puede recuperarse solo.
				gps.error = 'sin_senal';
			}
		},
		{ enableHighAccuracy: true, maximumAge: 5000, timeout: 30000 }
	);
}

/** ¿El vecino ya aceptó ver distancias en una visita anterior? */
export function quiereDistancias(): boolean {
	try {
		return localStorage.getItem(CLAVE_OPTIN) === '1';
	} catch {
		return false;
	}
}

/** Último fix si es reciente (para no esperar al GPS de nuevo al regar). */
export function fixReciente(maxMs = 15000): Fix | null {
	return gps.fix && Date.now() - gps.fix.ts <= maxMs ? gps.fix : null;
}
