<script lang="ts">
	import { onMount } from 'svelte';
	import { flip } from 'svelte/animate';
	import { resolve } from '$app/paths';
	import { ESTADO_INFO, type Estado } from '$lib/domain/estado';
	import { distanciaMetros, formatearDistancia } from '$lib/domain/distancia';
	import { ordenarArboles } from '$lib/domain/orden';
	import { gps, seguirPosicion, quiereDistancias } from '$lib/geo.svelte';
	import ArbolVoxel from '$lib/ui/ArbolVoxel.svelte';
	import PanelVecino from '$lib/features/premios/PanelVecino.svelte';
	import type { Escalon } from '$lib/domain/insignias';

	let { data } = $props();

	// Se recalcula solo cada vez que el GPS reporta una posición nueva: si el
	// vecino camina, la lista se reacomoda sola (y las filas se deslizan).
	const arboles = $derived(ordenarArboles(data.arboles, gps.fix));
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
		<div class="num sed">{sedientos}</div>
		<div class="lab">CON SED</div>
	</div>
	<div class="box panel">
		<div class="num fel">{regadosHoy}</div>
		<div class="lab">REGADOS HOY</div>
	</div>
</div>

<p class="cta-note">Para sumar hay que estar en el árbol y escanear su chapita.</p>

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

{#snippet fila(arbol: (typeof arboles)[number])}
	{@const info = ESTADO_INFO[(arbol.estado ?? 'muy_sediento') as Estado]}
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
	.cta-note {
		text-align: center;
		font-size: 16px;
		color: #2c4a1e;
		margin: 9px 4px 0;
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
