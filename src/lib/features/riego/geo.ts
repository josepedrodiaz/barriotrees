// Ubicación del vecino al regar. Si el árbol tiene coordenadas cargadas el
// servidor exige estar cerca; si el teléfono no da la ubicación mandamos null
// y el servidor decide (árboles sin coordenadas todavía no la exigen).

import { fixReciente } from '$lib/geo.svelte';

export interface Coordenadas {
	lat: number | null;
	lng: number | null;
}

export function obtenerUbicacion(timeoutMs = 8000): Promise<Coordenadas> {
	// Si el watcher de distancias ya tiene un fix fresco, no esperamos al GPS.
	const fix = fixReciente();
	if (fix) return Promise.resolve({ lat: fix.lat, lng: fix.lng });
	return new Promise((resolve) => {
		if (!('geolocation' in navigator)) {
			resolve({ lat: null, lng: null });
			return;
		}
		navigator.geolocation.getCurrentPosition(
			(pos) => resolve({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
			() => resolve({ lat: null, lng: null }),
			{ enableHighAccuracy: true, timeout: timeoutMs, maximumAge: 30000 }
		);
	});
}
