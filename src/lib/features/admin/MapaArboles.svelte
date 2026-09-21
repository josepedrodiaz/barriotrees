<script lang="ts">
	import { onMount } from 'svelte';
	import L from 'leaflet';
	import 'leaflet/dist/leaflet.css';
	import { gps, seguirPosicion } from '$lib/geo.svelte';
	import { moverArbol, type ArbolAdmin } from '$lib/features/admin/arboles';

	interface Props {
		arboles: ArbolAdmin[];
		onEditar: (arbol: ArbolAdmin) => void;
		onNuevoEnGps: (lat: number, lng: number) => void;
		onMover: (id: string, lat: number, lng: number) => void;
	}

	let { arboles, onEditar, onNuevoEnGps, onMover }: Props = $props();

	let contenedor: HTMLDivElement;
	let mapa: L.Map | null = null;
	let capaArboles: L.LayerGroup | null = null;
	let capaGps: L.LayerGroup | null = null;
	let marcadorYo: L.Marker | null = null;
	let circuloGps: L.Circle | null = null;
	let centradoGps = false;
	let aviso = $state<string | null>(null);

	const CENTRO_PLAZA: [number, number] = [-34.9787, -58.0204];

	// divIcon a mano: los íconos default de Leaflet se rompen con Vite (las
	// imágenes no se resuelven), así que el pin es un simple <div> de color.
	function iconoArbol(conCoords: boolean): L.DivIcon {
		return L.divIcon({
			className: 'pin-arbol',
			html: `<div class="pin-punto ${conCoords ? 'con' : 'sin'}"></div>`,
			iconSize: [18, 18],
			iconAnchor: [9, 9]
		});
	}

	function iconoYo(): L.DivIcon {
		return L.divIcon({
			className: 'pin-yo',
			html: '<div class="punto-yo"></div>',
			iconSize: [16, 16],
			iconAnchor: [8, 8]
		});
	}

	function dibujarArboles() {
		if (!mapa || !capaArboles) return;
		capaArboles.clearLayers();
		for (const a of arboles) {
			// Solo se plotean los árboles con coordenadas.
			if (a.lat == null || a.lng == null) continue;
			const marcador = L.marker([a.lat, a.lng], {
				icon: iconoArbol(true),
				draggable: true,
				title: a.codigo
			});
			marcador.on('click', () => onEditar(a));
			marcador.on('dragend', () => manejarArrastre(marcador, a));
			marcador.addTo(capaArboles);
		}
	}

	async function manejarArrastre(marcador: L.Marker, arbol: ArbolAdmin) {
		const pos = marcador.getLatLng();
		const lat = Number(pos.lat.toFixed(7));
		const lng = Number(pos.lng.toFixed(7));
		const res = await moverArbol(arbol.id, lat, lng);
		if (res.ok) {
			// El padre actualiza la lista (tabla + mapa) y la ficha si está abierta,
			// de forma reactiva. Mutar arbol.lat acá no refrescaba el form.
			onMover(arbol.id, lat, lng);
			aviso = null;
		} else {
			// Volver el pin a su lugar y avisar.
			if (arbol.lat != null && arbol.lng != null) {
				marcador.setLatLng([arbol.lat, arbol.lng]);
			}
			aviso = res.error;
		}
	}

	function dibujarGps() {
		if (!mapa || !capaGps) return;
		const fix = gps.fix;
		if (!fix) {
			capaGps.clearLayers();
			marcadorYo = null;
			circuloGps = null;
			return;
		}
		if (marcadorYo) {
			marcadorYo.setLatLng([fix.lat, fix.lng]);
		} else {
			marcadorYo = L.marker([fix.lat, fix.lng], {
				icon: iconoYo(),
				interactive: false
			}).addTo(capaGps);
		}
		if (circuloGps) {
			circuloGps.setLatLng([fix.lat, fix.lng]);
			circuloGps.setRadius(fix.precision);
		} else {
			circuloGps = L.circle([fix.lat, fix.lng], {
				radius: fix.precision,
				color: '#3fa9f5',
				fillColor: '#3fa9f5',
				fillOpacity: 0.12
			}).addTo(capaGps);
		}
		// La primera vez, centrar el mapa donde está el vecino.
		if (!centradoGps) {
			mapa.setView([fix.lat, fix.lng], Math.max(mapa.getZoom(), 17));
			centradoGps = true;
		}
	}

	function centrarInicial() {
		if (!mapa) return;
		const conCoords = arboles.filter((a) => a.lat != null && a.lng != null);
		if (conCoords.length) {
			mapa.fitBounds(
				L.latLngBounds(
					conCoords.map((a) => [a.lat as number, a.lng as number] as [number, number])
				),
				{ maxZoom: 18, padding: [30, 30] }
			);
		} else {
			mapa.setView(CENTRO_PLAZA, 17);
		}
	}

	onMount(() => {
		if (!contenedor) return;
		mapa = L.map(contenedor, { center: CENTRO_PLAZA, zoom: 17, maxZoom: 19 });

		const calles = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
			maxZoom: 19,
			attribution: '© OpenStreetMap'
		});
		const satelital = L.tileLayer(
			'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
			{ maxZoom: 19, attribution: 'Tiles © Esri — Source: Esri, Maxar, Earthstar Geographics' }
		);
		calles.addTo(mapa);
		L.control.layers({ 'Calle (OSM)': calles, 'Satelital (Esri)': satelital }).addTo(mapa);

		capaArboles = L.layerGroup().addTo(mapa);
		capaGps = L.layerGroup().addTo(mapa);

		dibujarArboles();
		centrarInicial();
		dibujarGps();
	});

	// Re-render de markers cuando cambia la lista de árboles (alta/edición/move).
	$effect(() => {
		dibujarArboles();
	});

	// Seguir el fix del GPS: punto azul + círculo de precisión + centrado.
	$effect(() => {
		dibujarGps();
	});

	const estadoGps = $derived.by(() => {
		const fix = gps.fix;
		if (!fix) return null;
		const p = fix.precision;
		if (p <= 6) return { texto: 'fino ✓', clase: 'verde' };
		if (p <= 12) return { texto: 'aceptable', clase: 'amarillo' };
		return { texto: 'esperá, afinando…', clase: 'rojo' };
	});

	function crearArbolEnGps() {
		if (!gps.fix) return;
		onNuevoEnGps(gps.fix.lat, gps.fix.lng);
	}
</script>

<div class="mapa-arboles panel">
	<div class="barra">
		<button class="btn sm" onclick={seguirPosicion}>📍 GPS en vivo</button>
		<button class="btn sm" disabled={!gps.fix} onclick={crearArbolEnGps}>➕ Árbol acá (GPS)</button>
	</div>
	<div class="lienzo">
		<div class="mapa" bind:this={contenedor}></div>
		{#if gps.fix}
			<div class="badge {estadoGps?.clase}">
				GPS ±{Math.round(gps.fix.precision)}m · {estadoGps?.texto}
			</div>
		{/if}
	</div>
	{#if aviso}<p class="aviso">{aviso}</p>{/if}
	{#if gps.error === 'permiso'}
		<p class="aviso">Ubicación denegada: habilitá el permiso del navegador para usar el GPS.</p>
	{/if}
	<p class="ayuda">Arrastrá un pin para moverlo · tocá un pin para editarlo.</p>
</div>

<style>
	.mapa-arboles {
		margin-bottom: 1rem;
	}
	.barra {
		display: flex;
		gap: 0.5rem;
		flex-wrap: wrap;
		padding: 0.6rem;
	}
	.lienzo {
		position: relative;
	}
	.mapa {
		position: relative;
		z-index: 0;
		height: 380px;
		width: 100%;
		background: #a9de9e;
	}
	.badge {
		position: absolute;
		bottom: 8px;
		left: 8px;
		z-index: 1000;
		font-family: var(--read);
		font-size: 15px;
		line-height: 1;
		padding: 5px 8px;
		border: 2px solid var(--edge-d);
		color: #fff;
	}
	.badge.verde {
		background: var(--feliz);
	}
	.badge.amarillo {
		background: var(--bien);
	}
	.badge.rojo {
		background: var(--sed);
	}
	.aviso {
		margin: 0.5rem 0.6rem;
		font-size: 0.85rem;
		color: var(--sed);
	}
	.ayuda {
		margin: 0.4rem 0.6rem 0.6rem;
		font-size: 0.8rem;
		color: var(--dim);
	}
	/* Los divIcon viven fuera del alcance de Svelte: estilos globales. */
	:global(.pin-punto) {
		width: 16px;
		height: 16px;
		border-radius: 50%;
		border: 3px solid var(--edge-d);
		box-sizing: border-box;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.5);
	}
	:global(.pin-punto.con) {
		background: var(--feliz);
	}
	:global(.pin-punto.sin) {
		background: #9aa3b0;
	}
	:global(.punto-yo) {
		width: 16px;
		height: 16px;
		border-radius: 50%;
		background: var(--water);
		border: 3px solid #fff;
		box-shadow:
			0 0 0 2px var(--water),
			0 1px 4px rgba(0, 0, 0, 0.5);
		box-sizing: border-box;
	}
</style>
