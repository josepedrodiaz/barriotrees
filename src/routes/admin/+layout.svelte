<script lang="ts">
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { sesion } from '$lib/features/auth/sesion.svelte';

	let { children } = $props();
</script>

<!-- Esto es solo la puerta de vidrio: si un vecino común llega acá, va a ver
     la pantalla pero no va a poder escribir nada. La cerradura real son las
     policies de admin en Postgres (BT-10). -->
{#if sesion.cargando}
	<p class="esperando">…</p>
{:else if !sesion.perfil?.es_admin}
	<h1>Panel de la comisión</h1>
	<p>Esta parte es para quienes administran los árboles.</p>
	{#if !sesion.session}
		<p><a href={resolve('/entrar')}>Entrar →</a></p>
	{/if}
	<p><a href={resolve('/')}>← volver a los árboles</a></p>
{:else}
	<nav class="panel">
		<a href={resolve('/admin')} class:activo={page.url.pathname === '/admin'}>Árboles</a>
		<a href={resolve('/admin/qrs')} class:activo={page.url.pathname === '/admin/qrs'}>Chapitas QR</a
		>
		<a href={resolve('/')}>Salir del panel</a>
	</nav>
	{@render children()}
{/if}

<style>
	.esperando {
		color: var(--dim);
	}
	nav {
		display: flex;
		gap: 1.25rem;
		font-size: 0.9rem;
		padding-bottom: 0.75rem;
		margin-bottom: 1.5rem;
		border-bottom: 2px solid var(--edge-l);
	}
	nav a {
		color: var(--dim);
		text-decoration: none;
	}
	nav a.activo {
		color: var(--ink);
		text-decoration: underline;
		text-underline-offset: 4px;
	}

	@media print {
		nav {
			display: none;
		}
	}
</style>
