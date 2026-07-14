// Distancia entre dos puntos (haversine) — espejo exacto de la fórmula que
// usa registrar_riego en Postgres para validar proximidad. Acá se usa solo
// para mostrar; la validación real siempre es del servidor.

const RADIO_TIERRA_M = 6371000;

export function distanciaMetros(lat1: number, lng1: number, lat2: number, lng2: number): number {
	const rad = (g: number) => (g * Math.PI) / 180;
	const a =
		Math.sin(rad(lat2 - lat1) / 2) ** 2 +
		Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(rad(lng2 - lng1) / 2) ** 2;
	return 2 * RADIO_TIERRA_M * Math.asin(Math.sqrt(a));
}

/** "8 m", "340 m", "1,2 km" — redondeo grueso: es una guía, no un GPS militar. */
export function formatearDistancia(metros: number): string {
	if (metros < 1000) return `${Math.round(metros)} m`;
	const km = metros / 1000;
	return `${km.toLocaleString('es-AR', { maximumFractionDigits: 1 })} km`;
}
