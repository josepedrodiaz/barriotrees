<script lang="ts">
	import { onMount } from 'svelte';
	import { flip } from 'svelte/animate';
	import { resolve } from '$app/paths';
	import { ESTADO_INFO, type Estado } from '$lib/domain/estado';
	import { distanciaMetros, formatearDistancia } from '$lib/domain/distancia';
	import { ordenarArboles } from '$lib/domain/orden';
	import { gps, seguirPosicion, quiereDistancias } from '$lib/geo.svelte';
	import ArbolVoxel from '$lib/ui/ArbolVoxel.svelte';

	let { data } = $props();

	// Se recalcula solo cada vez que el GPS reporta una posición nueva: si el
	// vecino camina, la lista se reacomoda sola (y las filas se deslizan).
	const arboles = $derived(ordenarArboles(data.arboles, gps.fix));
	const sedientos = $derived(
		arboles.filter((a) => a.estado === 'sediento' || a.estado === 'muy_sediento').length
	);

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

<p class="intro">Los árboles jóvenes de la plaza necesitan agua para volverse gigantes.</p>

{#if gps.error === 'permiso'}
	<p class="ubicacion">Sin permiso de ubicación no puedo mostrarte distancias.</p>
{:else if gps.siguiendo && !gps.fix}
	<p class="ubicacion">📡 Ubicándote…</p>
{:else if !gps.fix}
	<p class="ubicacion">
		<button class="enlace" onclick={seguirPosicion}>📍 Ver a cuántos metros estás</button>
	</p>
{/if}

<h1 class="section-h">
	💧 Necesitan agua <span class="n">({sedientos})</span>{#if gps.fix}
		· cerca tuyo{/if}
</h1>

<ul class="arboles">
	{#each arboles as arbol (arbol.codigo)}
		{@const info = ESTADO_INFO[(arbol.estado ?? 'muy_sediento') as Estado]}
		<li animate:flip={{ duration: 400 }}>
			<a class="panel" href={resolve('/arbol/[codigo]', { codigo: arbol.codigo ?? '' })}>
				<span class="mini"
					><ArbolVoxel estado={(arbol.estado ?? 'muy_sediento') as Estado} px={52} /></span
				>
				<span class="info">
					<span class="nm">{arbol.nombre ?? arbol.especie_nombre} · {arbol.codigo}</span>
					<span class="st">
						<span class="chip {info.clase}">{info.etiqueta}</span>
						<span class="datos"
							>{diasTexto(arbol.dias_sin_riego)}{#if distanciaA(arbol.lat, arbol.lng)}
								· 📍
								{distanciaA(arbol.lat, arbol.lng)}{/if}</span
						>
					</span>
				</span>
				<span class="go">▶</span>
			</a>
		</li>
	{:else}
		<li class="panel vacio">Todavía no hay árboles cargados.</li>
	{/each}
</ul>

<style>
	.intro {
		margin: 14px 4px 6px;
		text-align: center;
	}
	.section-h .n {
		color: var(--sed);
	}
	.arboles {
		list-style: none;
		padding: 0;
		margin: 0;
		display: flex;
		flex-direction: column;
		gap: 10px;
	}
	.arboles li a {
		display: flex;
		align-items: center;
		gap: 10px;
		padding: 8px 10px;
		text-decoration: none;
		color: var(--ink);
	}
	.arboles li a:active {
		transform: translateY(2px);
	}
	.mini {
		flex: none;
	}
	.info {
		flex: 1;
		min-width: 0;
	}
	.nm {
		display: block;
		font-family: var(--pixel);
		font-size: 9px;
		line-height: 1.5;
		color: #fff;
	}
	.st {
		display: block;
		margin-top: 6px;
	}
	/* El estado va de chapita bajo el nombre y no en una columna: "¡Muy
	   sediento!" no entra al costado sin desbordarse. */
	.chip {
		font-family: var(--pixel);
		font-size: 7px;
		line-height: 1.5;
		padding: 4px 7px;
		/* El color lo pone la clase de estado; el borde lo sigue. */
		border: 2px solid currentColor;
		display: inline-block;
	}
	.datos {
		color: var(--dim);
		font-size: 15px;
		margin-left: 6px;
	}
	.go {
		font-family: var(--pixel);
		font-size: 12px;
		color: var(--violet-l);
		flex: none;
	}
	.vacio {
		padding: 14px;
		text-align: center;
	}
	.ubicacion {
		margin: 0 4px;
		text-align: center;
		font-size: 17px;
	}
	button.enlace {
		background: none;
		border: none;
		padding: 0;
		font: inherit;
		color: var(--violet-d);
		text-decoration: underline;
		cursor: pointer;
	}
</style>
