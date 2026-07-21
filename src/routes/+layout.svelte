<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { pwaInfo } from 'virtual:pwa-info';
	import favicon from '$lib/assets/favicon.svg';
	import { sesion, seguirSesion } from '$lib/features/auth/sesion.svelte';
	import ArbolVoxel from '$lib/ui/ArbolVoxel.svelte';
	import Bienvenida from '$lib/features/onboarding/Bienvenida.svelte';
	import { bienvenida, yaLaVio } from '$lib/features/onboarding/vista.svelte';

	let { children } = $props();

	seguirSesion();

	// PWA (BT-32): registra el service worker que deja la app instalada y con el
	// shell precacheado — abre al toque aunque la señal de la plaza esté floja.
	onMount(() => {
		if ('serviceWorker' in navigator) {
			import('virtual:pwa-register').then(({ registerSW }) => registerSW({ immediate: true }));
		}
	});

	const manifestLink = $derived(pwaInfo ? pwaInfo.webManifest.linkTag : '');

	// Va en el layout y no en una pantalla: el vecino puede caer en cualquier
	// lado (una chapita lo deja en la ficha del árbol, un link en la home).
	// Se espera a saber si hay sesión para no llegar tarde ni de más.
	const mostrarBienvenida = $derived(
		!sesion.cargando && !sesion.session && !bienvenida.cerrada && !yaLaVio()
	);
	// Si llegó escaneando una chapita, el paso 2 le habla de SU árbol.
	const arbolDelQr = $derived(page.data.arbol?.nombre ?? page.data.arbol?.especie_nombre);
</script>

{#if mostrarBienvenida}
	<Bienvenida arbol={arbolDelQr} />
{/if}

<svelte:head>
	<link rel="icon" href={favicon} type="image/svg+xml" />
	<!-- PWA: el manifest (instalable), el ícono de iOS y el color de la barra
	     del sistema en el violeta del panel. -->
	<!-- eslint-disable-next-line svelte/no-at-html-tags -- linkTag lo genera el plugin, no el usuario -->
	{@html manifestLink}
	<link rel="apple-touch-icon" href="/iconos/apple-touch-icon.png" />
	<meta name="theme-color" content="#221c36" />
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

<!-- Como la demo: el logo manda y a la derecha va lo mínimo. El nombre y el
     nivel del vecino viven en el panel de la home, no acá — repetirlos era lo
     que apretaba la barra. -->
<header>
	<a class="logo" href={resolve('/')}><ArbolVoxel salud={1} px={34} />Árboles <b>Gigantes</b></a>
	{#if !sesion.cargando}
		{#if sesion.perfil}
			<a class="puntos" href={resolve('/insignias')} title="Tus insignias y tu cuenta">
				🎖 {sesion.perfil.puntos}
			</a>
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
		/* En pixel, 16 caracteres a 12px ya son ~220px: en un teléfono angosto no
		   entra con nada al lado. Se achica con la pantalla en vez de partirse. */
		font-family: var(--pixel);
		font-size: clamp(9px, 3.1vw, 12px);
		color: var(--feliz);
		text-shadow: 2px 2px 0 #0d3d1f;
		text-decoration: none;
		display: flex;
		gap: 6px;
		align-items: center;
		flex: none;
		white-space: nowrap;
	}
	.logo :global(b) {
		color: var(--violet-l);
		text-shadow: 2px 2px 0 #2c1f52;
	}
	.puntos {
		margin-left: auto;
		flex: none;
		font-family: var(--pixel);
		font-size: 10px;
		color: var(--gold);
		text-shadow: 2px 2px 0 #6b4d00;
		text-decoration: none;
		white-space: nowrap;
		border: 2px solid #8a6a10;
		padding: 5px 6px;
	}
	.entrar {
		font-family: var(--read);
		font-size: 18px;
		color: var(--dim);
		text-decoration: underline;
		flex: none;
		white-space: nowrap;
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
