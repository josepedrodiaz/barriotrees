<script lang="ts">
	import '../app.css';
	import { resolve } from '$app/paths';
	import favicon from '$lib/assets/favicon.svg';
	import { sesion, seguirSesion, salir } from '$lib/features/auth/sesion.svelte';

	let { children } = $props();

	seguirSesion();
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<!-- Las fuentes son lo primero que se nota faltando: que empiecen a bajar
	     junto con el HTML y no cuando el CSS las descubre. -->
	<link
		rel="preload"
		href="/fuentes/press-start-2p-latin.woff2"
		as="font"
		type="font/woff2"
		crossorigin="anonymous"
	/>
	<link
		rel="preload"
		href="/fuentes/vt323-latin.woff2"
		as="font"
		type="font/woff2"
		crossorigin="anonymous"
	/>
</svelte:head>

<header>
	<a class="logo" href={resolve('/')}>🌳 Árboles <b>Gigantes</b></a>
	{#if !sesion.cargando}
		{#if sesion.perfil}
			<a class="vecino" href={resolve('/insignias')}>
				<span class="nombre">{sesion.perfil.nombre}</span>
				<span class="puntos">{sesion.perfil.puntos}</span>
			</a>
			<button class="salir" onclick={salir}>salir</button>
		{:else}
			<a class="entrar" href={resolve('/entrar')}>entrar</a>
		{/if}
	{/if}
</header>

<main>
	{@render children()}
</main>

<style>
	header {
		position: sticky;
		top: 0;
		z-index: 30;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 8px;
		padding: 10px 12px;
		background: var(--panel2);
		border-bottom: 4px solid var(--edge-d);
	}
	.logo {
		font-family: var(--pixel);
		font-size: 12px;
		color: var(--feliz);
		text-shadow: 2px 2px 0 #0d3d1f;
		text-decoration: none;
		display: flex;
		gap: 6px;
		align-items: center;
	}
	.logo :global(b) {
		color: var(--violet-l);
		text-shadow: 2px 2px 0 #2c1f52;
	}
	.vecino {
		display: flex;
		align-items: center;
		gap: 6px;
		margin-left: auto;
		min-width: 0;
		text-decoration: none;
		color: var(--dim);
	}
	.nombre {
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		max-width: 9ch;
	}
	.puntos {
		font-family: var(--pixel);
		font-size: 11px;
		color: var(--gold);
		text-shadow: 2px 2px 0 #6b4d00;
	}
	.entrar,
	.salir {
		font-family: var(--read);
		font-size: 18px;
		color: var(--dim);
		background: none;
		border: none;
		padding: 0;
		cursor: pointer;
		text-decoration: underline;
	}
	.entrar {
		margin-left: auto;
	}

	/* Imprimir es solo para las chapitas QR: la app desaparece y queda la hoja.
	   Va acá y no en app.css porque estas reglas tienen que compartir el
	   scoping de las de arriba para poder pisarlas. */
	@media print {
		header {
			display: none;
		}
		main {
			max-width: none;
			padding: 0;
		}
	}
</style>
