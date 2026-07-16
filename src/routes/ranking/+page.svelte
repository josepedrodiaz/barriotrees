<script lang="ts">
	import { resolve } from '$app/paths';
	import { sesion } from '$lib/features/auth/sesion.svelte';

	let { data } = $props();

	const yo = $derived(sesion.session?.user.id);
	const nro = (n: number) => n.toLocaleString('es-AR');
	// El podio lleva medalla; del 4º para abajo, el número.
	const medalla = (p: number) => (p === 1 ? '🥇' : p === 2 ? '🥈' : p === 3 ? '🥉' : `${p}`);
</script>

<svelte:head>
	<title>Ranking · Árboles Gigantes</title>
</svelte:head>

<a class="back" href={resolve('/')}>◀ VOLVER</a>

<h1 class="titulo">RANKING DEL BARRIO</h1>
<p class="bajada">Quién cuidó más la plaza. Se ordena por puntos, en vivo.</p>

{#if data.ranking.length}
	<ol class="tabla">
		{#each data.ranking as fila (fila.id)}
			<li class="panel" class:soy-yo={fila.id === yo} class:podio={(fila.puesto ?? 99) <= 3}>
				<span class="puesto">{medalla(fila.puesto ?? 0)}</span>
				<span class="nombre">
					{fila.nombre}{#if fila.id === yo}<span class="vos"> · vos</span>{/if}
				</span>
				<span class="datos">
					<span class="puntos">{nro(fila.puntos ?? 0)}</span>
					<span class="lab">pts</span>
				</span>
			</li>
		{/each}
	</ol>
{:else}
	<p class="vacio panel">Todavía nadie regó. Sé el primero 🌱</p>
{/if}

{#if !sesion.session}
	<p class="sumate">
		<a class="btn wide" href={resolve('/entrar')}>ENTRAR Y APARECER ACÁ</a>
	</p>
{/if}

<style>
	.back {
		display: inline-block;
		font-family: var(--pixel);
		font-size: 9px;
		color: var(--tinta-pasto);
		text-decoration: none;
		padding: 6px 0;
		margin-bottom: 4px;
	}
	.titulo {
		color: #fff;
		text-shadow: 3px 3px 0 #000;
		margin: 8px 0 4px;
	}
	.bajada {
		margin: 0 4px 14px;
		font-size: 16px;
	}
	.tabla {
		list-style: none;
		padding: 0;
		margin: 0;
		display: flex;
		flex-direction: column;
		gap: 8px;
	}
	.tabla li {
		display: flex;
		align-items: center;
		gap: 12px;
		padding: 10px 12px;
	}
	.puesto {
		font-family: var(--pixel);
		font-size: 13px;
		width: 2ch;
		flex: none;
		text-align: center;
		color: var(--dim);
	}
	.podio .puesto {
		font-size: 20px;
	}
	.nombre {
		flex: 1;
		min-width: 0;
		color: #fff;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.vos {
		color: var(--gold);
	}
	.datos {
		flex: none;
		display: flex;
		align-items: baseline;
		gap: 4px;
	}
	.puntos {
		font-family: var(--pixel);
		font-size: 13px;
		color: var(--gold);
		text-shadow: 2px 2px 0 #6b4d00;
	}
	.lab {
		font-size: 15px;
		color: var(--dim);
	}
	/* Tu fila resalta con borde dorado: te encontrás de un vistazo. */
	.soy-yo {
		border-color: var(--gold);
	}
	.vacio {
		padding: 16px;
		text-align: center;
		color: var(--dim);
	}
	.sumate {
		margin-top: 18px;
	}
	.sumate a {
		text-decoration: none;
	}
</style>
