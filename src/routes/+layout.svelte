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
</svelte:head>

{#if !sesion.cargando}
	<header>
		{#if sesion.perfil}
			<span class="vecino">
				<strong>{sesion.perfil.nombre}</strong>
				<span class="puntos">{sesion.perfil.puntos} pts</span>
			</span>
			<button class="salir" onclick={salir}>salir</button>
		{:else}
			<span class="vecino anonimo">Estás sin cuenta</span>
			<a class="entrar" href={resolve('/entrar')}>entrar</a>
		{/if}
	</header>
{/if}

<main>
	{@render children()}
</main>

<style>
	header {
		max-width: 480px;
		margin: 0 auto;
		padding: 0.6rem 1.25rem;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.75rem;
		font-size: 0.9rem;
		border-bottom: 1px solid #e8e4da;
	}
	.vecino {
		display: flex;
		align-items: baseline;
		gap: 0.5rem;
		min-width: 0;
	}
	.vecino strong {
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.puntos {
		color: var(--verde-oscuro);
		font-weight: 700;
		white-space: nowrap;
	}
	.anonimo {
		color: var(--tinta-suave);
	}
	.entrar {
		font-weight: 600;
		white-space: nowrap;
	}
	.salir {
		background: none;
		border: none;
		padding: 0;
		font: inherit;
		color: var(--tinta-suave);
		text-decoration: underline;
		cursor: pointer;
	}
</style>
