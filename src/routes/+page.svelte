<script lang="ts">
	import { onMount } from 'svelte';
	import { flip } from 'svelte/animate';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { ESTADO_INFO, type Estado } from '$lib/domain/estado';
	import { distanciaMetros, formatearDistancia } from '$lib/domain/distancia';
	import { ordenarArboles } from '$lib/domain/orden';
	import { gps, seguirPosicion, quiereDistancias } from '$lib/geo.svelte';
	import ArbolVoxel from '$lib/ui/ArbolVoxel.svelte';
	import PanelVecino from '$lib/features/premios/PanelVecino.svelte';
	import EscanerQr from '$lib/features/riego/EscanerQr.svelte';
	import { registrarEscaneo } from '$lib/features/riego/escaneo.svelte';
	import type { Escalon } from '$lib/domain/insignias';

	let { data } = $props();

	let escaneando = $state(false);

	// Escanear desde la home es el camino principal: apuntás a una chapita y caés
	// en ese árbol, ya reconocido y listo para regar (decisión 17).
	function alEscanear(codigo: string) {
		escaneando = false;
		registrarEscaneo(codigo);
		goto(resolve('/arbol/[codigo]', { codigo }));
	}

	// Se recalcula solo cada vez que el GPS reporta una posición nueva: si el
	// vecino camina, la lista se reacomoda sola (y las filas se deslizan).
	const arboles = $derived(ordenarArboles(data.arboles, gps.fix));
	// El suelo mojado es global de la plaza: si llovió, no se manda a regar a
	// nadie hoy, aunque los árboles tengan sed de fondo (BT: riego suelo mojado).
	const sueloMojado = $derived(data.arboles[0]?.suelo_saturado ?? false);
	const sedientos = $derived(
		arboles.filter((a) => a.estado === 'sediento' || a.estado === 'muy_sediento').length
	);
	const regadosHoy = $derived(
		arboles.filter((a) => a.dias_sin_riego !== null && a.dias_sin_riego < 1).length
	);
	// Como la demo: los que piden agua arriba y el resto abajo. Adentro de cada
	// grupo sigue mandando la cercanía, así que la lista se reacomoda al caminar.
	const conSed = $derived(
		arboles.filter((a) => a.estado === 'sediento' || a.estado === 'muy_sediento')
	);
	const yaEstan = $derived(
		arboles.filter((a) => a.estado !== 'sediento' && a.estado !== 'muy_sediento')
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

<PanelVecino escalera={data.escalera as Escalon[]} />

<div class="stat">
	<div class="box panel">
		{#if sueloMojado}
			<div class="num fel">🌧️</div>
			<div class="lab">LLOVIÓ</div>
		{:else}
			<div class="num sed">{sedientos}</div>
			<div class="lab">CON SED</div>
		{/if}
	</div>
	<div class="box panel">
		<div class="num fel">{regadosHoy}</div>
		<div class="lab">REGADOS HOY</div>
	</div>
</div>

<button class="btn wide escanear" onclick={() => (escaneando = true)}>📷 ESCANEAR QR</button>

{#if escaneando}
	<EscanerQr onCodigo={alEscanear} onCancelar={() => (escaneando = false)} />
{/if}

{#if gps.error === 'permiso'}
	<p class="ubicacion">Sin permiso de ubicación no puedo mostrarte distancias.</p>
{:else if gps.siguiendo && !gps.fix}
	<p class="ubicacion">📡 Ubicándote…</p>
{:else if !gps.fix}
	<p class="ubicacion">
		<button class="enlace" onclick={seguirPosicion}>📍 Ver a cuántos metros estás</button>
	</p>
{/if}

{#if sueloMojado}
	<div class="lluvia-hoy panel">
		<div class="lh-h">🌧️ Hoy no hace falta regar</div>
		<p>
			Llovió y el suelo está tomando agua. Volvé cuando se seque — podés verlo desde tu casa, en
			esta app.
		</p>
	</div>

	<h2 class="section-h">La plaza</h2>
	<ul class="arboles">
		{#each arboles as arbol (arbol.codigo)}
			<li animate:flip={{ duration: 400 }}>{@render fila(arbol)}</li>
		{/each}
	</ul>
{:else}
	<h1 class="section-h">
		💧 Necesitan agua <span class="n">({sedientos})</span>{#if gps.fix}
			· cerca tuyo{/if}
	</h1>

	{#if conSed.length}
		<ul class="arboles">
			{#each conSed as arbol (arbol.codigo)}
				<li animate:flip={{ duration: 400 }}>{@render fila(arbol)}</li>
			{/each}
		</ul>
	{:else}
		<p class="vacio panel">Ninguno urgente 🎉</p>
	{/if}

	{#if yaEstan.length}
		<h2 class="section-h">Ya están bien</h2>
		<ul class="arboles">
			{#each yaEstan as arbol (arbol.codigo)}
				<li animate:flip={{ duration: 400 }}>{@render fila(arbol)}</li>
			{/each}
		</ul>
	{/if}
{/if}

<a class="btn wide ranking-btn" href={resolve('/ranking')}>🏆 RANKING DEL BARRIO</a>

{#snippet fila(arbol: (typeof arboles)[number])}
	{@const info = ESTADO_INFO[(arbol.estado ?? 'muy_sediento') as Estado]}
	<a class="panel" href={resolve('/arbol/[codigo]', { codigo: arbol.codigo ?? '' })}>
		<span class="mini"
			><ArbolVoxel
				estado={sueloMojado ? 'feliz' : ((arbol.estado ?? 'muy_sediento') as Estado)}
				px={52}
			/></span
		>
		<span class="info">
			<span class="nm">{arbol.nombre ?? arbol.especie_nombre} · {arbol.codigo}</span>
			<span class="st">
				{#if sueloMojado}
					<span class="chip mojado">🌧 Mojado</span>
					<span class="datos"
						>{#if distanciaA(arbol.lat, arbol.lng)}📍 {distanciaA(arbol.lat, arbol.lng)}{/if}</span
					>
				{:else}
					<span class="chip {info.clase}">{info.etiqueta}</span>
					<span class="datos"
						>{diasTexto(arbol.dias_sin_riego)}{#if distanciaA(arbol.lat, arbol.lng)}
							· 📍
							{distanciaA(arbol.lat, arbol.lng)}{/if}</span
					>
				{/if}
			</span>
		</span>
		<span class="go">▶</span>
	</a>
{/snippet}

<style>
	.stat {
		display: flex;
		gap: 10px;
		margin: 14px 0 12px;
	}
	.stat .box {
		flex: 1;
		padding: 12px;
		text-align: center;
	}
	.stat .num {
		font-family: var(--pixel);
		font-size: 22px;
	}
	.stat .num.sed {
		color: var(--sed);
	}
	.stat .num.fel {
		color: var(--feliz);
	}
	.stat .lab {
		font-size: 16px;
		color: var(--dim);
		margin-top: 6px;
	}
	.escanear {
		margin-top: 4px;
	}
	.ranking-btn {
		margin-top: 26px;
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
		/* La pixel se lee mejor en mayúsculas; así lo hace la demo. */
		text-transform: uppercase;
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
		text-transform: uppercase;
	}
	.chip.mojado {
		color: var(--violet-l);
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
		padding: 16px;
		text-align: center;
		color: var(--dim);
	}
	.lluvia-hoy {
		padding: 18px 16px;
		text-align: center;
		border: 2px solid var(--violet-d);
	}
	.lluvia-hoy .lh-h {
		font-family: var(--pixel);
		font-size: 13px;
		line-height: 1.6;
		color: var(--violet-l);
		margin-bottom: 10px;
	}
	.lluvia-hoy p {
		margin: 0;
		font-size: 18px;
		color: var(--dim);
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
