<script lang="ts">
	import { resolve } from '$app/paths';
	import { supabase } from '$lib/supabase';
	import { sesion } from '$lib/features/auth/sesion.svelte';
	import QrDeCanje from '$lib/features/premios/QrDeCanje.svelte';
	import Pin from '$lib/ui/Pin.svelte';

	let { data } = $props();

	interface Canje {
		insignia_id: string;
		nombre: string;
		estado: string;
		token: string;
	}

	let canjes: Canje[] = $state([]);
	let cargadoPara: string | null = $state(null);

	// Los tokens de canje no se leen de la tabla (son privados): los da la RPC
	// mis_canjes, que solo devuelve los del vecino logueado. Se carga cuando la
	// sesión está lista y se recarga si cambia de cuenta.
	$effect(() => {
		const id = sesion.session?.user.id;
		if (sesion.cargando || !id || cargadoPara === id) return;
		cargadoPara = id;
		cargar();
	});

	async function cargar() {
		const { data: mis } = await supabase.rpc('mis_canjes');
		const c = mis as { ok?: boolean; canjes?: Canje[] } | null;
		if (c?.ok) canjes = c.canjes ?? [];
	}

	const ganados = $derived(new Set(canjes.map((c) => c.insignia_id)));
	const pendientes = $derived(canjes.filter((c) => c.estado === 'pendiente'));
	const entregados = $derived(canjes.filter((c) => c.estado === 'entregado'));

	// La galería: todos los pines del catálogo, marcando cuáles ganó el vecino.
	// Los que faltan se muestran muy grises — se ve lo que hay para conseguir.
	const galeria = $derived(
		data.pines.map((p) => ({ ...p, ganado: ganados.has(p.id) }))
	);
</script>

<svelte:head>
	<title>Premios · Árboles Gigantes</title>
</svelte:head>

<p class="volver"><a href={resolve('/')}>◀ volver</a></p>

<h1 class="titulo">Tus premios</h1>

{#if sesion.cargando}
	<p class="cargando">Cargando tus pines…</p>
{:else if !sesion.session}
	<div class="intro panel">
		<p>Los pines que ganás son tuyos, pero necesitás una cuenta para guardarlos y canjearlos.</p>
		<a class="btn gold wide" href={resolve('/entrar')}>CREAR CUENTA / ENTRAR</a>
	</div>
{:else}
	<p class="sub">Tu colección de pines: {ganados.size} de {data.pines.length}</p>

	<div class="galeria">
		{#each galeria as p (p.id)}
			<div class="celda" class:falta={!p.ganado}>
				<Pin px={72} alt={p.ganado ? `Pin ${p.nombre}` : ''} />
				<span class="pn">{p.nombre}</span>
			</div>
		{/each}
	</div>

	{#if pendientes.length}
		<h2 class="section-h">
			{pendientes.length === 1
				? '🎁 Tenés un pin para canjear'
				: `🎁 Tenés ${pendientes.length} pines para canjear`}
		</h2>
		<p class="bajada">Mostrale cada QR a quien te entrega el pin.</p>
		{#each pendientes as c (c.insignia_id)}
			<QrDeCanje nombre={c.nombre} token={c.token} urlBase={data.urlBase} />
		{/each}
	{/if}

	<details class="como">
		<summary>¿Cómo consigo los pines de verdad?</summary>
		<p>
			Cada pin de la colección es un <b>pin de metal</b>, hecho a mano. Cuando ganás uno, te lo
			entrega la comisión en persona: le mostrás el QR desde acá, lo escanea, y el pin es tuyo. Cada
			QR sirve una sola vez.
		</p>
		{#if entregados.length}
			<!-- El QR de un pin entregado sigue accesible: si la comisión lo marcó
			     entregado por error, el vecino tiene que poder mostrarlo de nuevo
			     para que el admin lo escanee y revierta (BT-39). -->
			<p class="mini">¿La comisión marcó un pin por error? Volvé a mostrar su QR:</p>
			{#each entregados as c (c.insignia_id)}
				<QrDeCanje nombre={c.nombre} token={c.token} urlBase={data.urlBase} />
			{/each}
		{/if}
	</details>
{/if}

<style>
	.volver {
		margin: 4px;
	}
	.volver a {
		color: var(--violet-l);
	}
	.titulo {
		font-family: var(--pixel);
		font-size: 18px;
		line-height: 1.5;
		color: var(--violet-l);
		text-align: center;
		margin: 8px 0 4px;
		text-shadow: 2px 2px 0 #000;
	}
	.cargando {
		text-align: center;
		color: var(--dim);
		font-size: 17px;
	}
	.sub {
		text-align: center;
		color: var(--dim);
		font-size: 16px;
		margin: 0 0 18px;
	}
	/* La galería es lo principal de la página: una grilla de pines. Los ganados
	   se ven a todo color; los que faltan quedan muy apagados, como silueta de lo
	   que hay para conseguir. */
	.galeria {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 18px 6px;
		margin-bottom: 24px;
	}
	.celda {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 8px;
		text-align: center;
	}
	.celda.falta {
		filter: grayscale(1) brightness(0.55);
		opacity: 0.28;
	}
	.pn {
		font-family: var(--pixel);
		font-size: 8px;
		line-height: 1.5;
		color: var(--gold);
		text-shadow: 1px 1px 0 #000;
	}
	.celda.falta .pn {
		color: var(--dim);
		text-shadow: none;
	}
	.section-h {
		font-family: var(--pixel);
		font-size: 13px;
		color: var(--gold);
		text-align: center;
		margin: 8px 0 6px;
		text-shadow: 2px 2px 0 #6b4e08;
	}
	.bajada {
		font-size: 16px;
		color: var(--dim);
		text-align: center;
		margin: 4px 0 12px;
	}
	/* El disclaimer de canje ya no es el bloque principal: vive plegado al pie. */
	.como {
		margin-top: 20px;
		border-top: 2px solid var(--edge-d);
		padding-top: 12px;
	}
	.como summary {
		color: var(--violet-l);
		cursor: pointer;
		font-size: 16px;
		text-align: center;
	}
	.como p {
		font-size: 16px;
		color: var(--dim);
		line-height: 1.4;
		margin: 10px 0 0;
	}
	.como .mini {
		margin-top: 14px;
		font-size: 15px;
	}
</style>
