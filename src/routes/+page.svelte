<script lang="ts">
	import { resolve } from '$app/paths';
	import { ESTADO_INFO, type Estado } from '$lib/domain/estado';

	let { data } = $props();

	function diasTexto(dias: number | null): string {
		if (dias === null) return 'nunca regado';
		if (dias < 1) return 'regado hoy';
		const d = Math.floor(dias);
		return d === 1 ? '1 día sin riego' : `${d} días sin riego`;
	}
</script>

<svelte:head>
	<title>Árboles Gigantes</title>
</svelte:head>

<h1>Árboles Gigantes</h1>
<p>
	Los árboles jóvenes de la Plaza Gigante del Oeste necesitan agua para volverse gigantes. Estos son
	los que más la necesitan ahora:
</p>

<ul class="arboles">
	{#each data.arboles as arbol (arbol.codigo)}
		{@const info = ESTADO_INFO[(arbol.estado ?? 'muy_sediento') as Estado]}
		<li>
			<a href={resolve('/arbol/[codigo]', { codigo: arbol.codigo ?? '' })}>
				<span class="emoji">{info.emoji}</span>
				<span class="quien">
					<strong>{arbol.nombre ?? arbol.especie_nombre} · {arbol.codigo}</strong>
					<small>{diasTexto(arbol.dias_sin_riego)}</small>
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
</style>
