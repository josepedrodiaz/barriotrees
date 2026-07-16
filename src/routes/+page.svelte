<script lang="ts">
	import { onMount } from 'svelte';
	import { flip } from 'svelte/animate';
	import { resolve } from '$app/paths';
	import { ESTADO_INFO, type Estado } from '$lib/domain/estado';
	import { distanciaMetros, formatearDistancia } from '$lib/domain/distancia';
	import { ordenarArboles } from '$lib/domain/orden';
	import { gps, seguirPosicion, quiereDistancias } from '$lib/geo.svelte';

	let { data } = $props();

	// Se recalcula solo cada vez que el GPS reporta una posición nueva: si el
	// vecino camina, la lista se reacomoda sola (y las filas se deslizan).
	const arboles = $derived(ordenarArboles(data.arboles, gps.fix));

	onMount(() => {
		if (quiereDistancias()) seguirPosicion();
	});

	function diasTexto(dias: number | null): string {
		if (dias === null) return 'nunca regado';
		if (dias < 1) return 'regado hoy';
		const d = Math.floor(dias);
		return d === 1 ? '1 día sin riego' : `${d} días sin riego`;
	}

	function distanciaA(lat: number | null, lng: number | null): string | null {
		if (!gps.fix || lat === null || lng === null) return null;
		return formatearDistancia(distanciaMetros(gps.fix.lat, gps.fix.lng, lat, lng));
	}
</script>

<svelte:head>
	<title>Árboles Gigantes</title>
</svelte:head>

<h1>Árboles Gigantes</h1>
<p>
	Los árboles jóvenes de la Plaza Gigante del Oeste necesitan agua para volverse gigantes. Estos son
	los que más la necesitan ahora{#if gps.fix}, y de esos, los que tenés más cerca{/if}:
</p>

{#if gps.error === 'permiso'}
	<p class="ubicacion aviso-gps">
		Sin permiso de ubicación no puedo mostrarte distancias. Se activa desde los ajustes del
		navegador.
	</p>
{:else if gps.siguiendo && !gps.fix}
	<p class="ubicacion aviso-gps">📡 Ubicándote…</p>
{:else if !gps.fix}
	<p class="ubicacion">
		<button class="enlace" onclick={seguirPosicion}
			>📍 Mostrar a cuántos metros estás de cada árbol</button
		>
	</p>
{/if}

<ul class="arboles">
	{#each arboles as arbol (arbol.codigo)}
		{@const info = ESTADO_INFO[(arbol.estado ?? 'muy_sediento') as Estado]}
		<li animate:flip={{ duration: 400 }}>
			<a href={resolve('/arbol/[codigo]', { codigo: arbol.codigo ?? '' })}>
				<span class="emoji">{info.emoji}</span>
				<span class="quien">
					<strong>{arbol.nombre ?? arbol.especie_nombre} · {arbol.codigo}</strong>
					<small>
						{diasTexto(arbol.dias_sin_riego)}{#if distanciaA(arbol.lat, arbol.lng)}&nbsp;· 📍 a
							{distanciaA(arbol.lat, arbol.lng)}{/if}
					</small>
				</span>
				<span class="estado {info.clase}">{info.etiqueta}</span>
			</a>
		</li>
	{:else}
		<li>Todavía no hay árboles cargados.</li>
	{/each}
</ul>

<style>
	.arboles {
		list-style: none;
		padding: 0;
		margin: 2rem 0 0;
	}
	.arboles li a {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		padding: 0.85rem 0;
		text-decoration: none;
		color: inherit;
		border-bottom: 1px solid #e8e4da;
	}
	.emoji {
		font-size: 1.6rem;
	}
	.quien {
		flex: 1;
		display: flex;
		flex-direction: column;
	}
	.quien small {
		color: var(--tinta-suave);
	}
	.estado {
		font-weight: 700;
		font-size: 0.9rem;
	}
	.ubicacion {
		margin: 0.5rem 0 0;
	}
	.aviso-gps {
		color: var(--tinta-suave);
		font-size: 0.9rem;
	}
	button.enlace {
		background: none;
		border: none;
		padding: 0;
		font: inherit;
		font-size: 0.95rem;
		color: var(--verde-oscuro);
		text-decoration: underline;
		cursor: pointer;
	}
</style>
