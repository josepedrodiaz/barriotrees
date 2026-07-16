<script lang="ts">
	import QRCode from 'qrcode';

	let { data } = $props();

	// El QR es la única puerta de entrada al juego: si sale mal impreso, el
	// árbol queda mudo. Nivel de corrección alto = sigue leyéndose aunque la
	// chapita se manche, se raye o le dé el sol dos veranos.
	const OPCIONES = { errorCorrectionLevel: 'H' as const, margin: 1, width: 420 };

	// Se guardan los excluidos y no los elegidos: así el default es "todos" sin
	// tener que copiar la lista de árboles a un estado que se desactualiza.
	let excluidos: string[] = $state([]);
	let qrs: Record<string, string> = $state({});

	const elegidos = $derived(data.arboles.filter((a) => !excluidos.includes(a.codigo!)));

	function alternar(codigo: string) {
		excluidos = excluidos.includes(codigo)
			? excluidos.filter((c) => c !== codigo)
			: [...excluidos, codigo];
	}

	const url = (codigo: string) => `${data.urlBase}/arbol/${codigo}`;

	$effect(() => {
		for (const a of elegidos) {
			if (qrs[a.codigo!]) continue;
			QRCode.toDataURL(url(a.codigo!), OPCIONES).then((d) => (qrs[a.codigo!] = d));
		}
	});

	function todos(valor: boolean) {
		excluidos = valor ? [] : data.arboles.map((a) => a.codigo!);
	}
</script>

<svelte:head>
	<title>Chapitas QR · Panel</title>
</svelte:head>

<div class="barra">
	<h1>Chapitas QR</h1>
	<p>
		Elegí los árboles, imprimí y recortá por la línea punteada. Cada QR abre la ficha de ese árbol.
	</p>
	<p class="apunta">Apuntan a <code>{data.urlBase}</code></p>

	<div class="filtros">
		<button class="enlace" onclick={() => todos(true)}>todos</button>
		<button class="enlace" onclick={() => todos(false)}>ninguno</button>
		<span class="cuenta">{elegidos.length} seleccionados</span>
	</div>

	<ul class="lista">
		{#each data.arboles as a (a.codigo)}
			<li>
				<label>
					<input
						type="checkbox"
						checked={!excluidos.includes(a.codigo!)}
						onchange={() => alternar(a.codigo!)}
					/>
					{a.codigo}
					<span class="suave">{a.nombre ?? a.especie_nombre}</span>
				</label>
			</li>
		{/each}
	</ul>

	<button class="primario" onclick={() => window.print()} disabled={elegidos.length === 0}>
		Imprimir {elegidos.length} chapita{elegidos.length === 1 ? '' : 's'}
	</button>
	<p class="consejo">
		Consejo: papel grueso o etiqueta plástica. Y colgá cada chapita en el árbol que dice — el código
		tiene que coincidir con el del relevamiento.
	</p>
</div>

<div class="hoja">
	{#each elegidos as a (a.codigo)}
		<div class="chapita">
			<div class="marca">🌳 Árboles Gigantes</div>
			{#if qrs[a.codigo!]}
				<img src={qrs[a.codigo!]} alt="QR de {a.codigo}" />
			{:else}
				<div class="hueco"></div>
			{/if}
			<div class="nombre">{a.nombre ?? a.especie_nombre}</div>
			<div class="gancho">Regame y sumá puntos 💧</div>
			<div class="pie">Escaneá con la cámara del celu · {a.codigo}</div>
		</div>
	{/each}
</div>

<style>
	h1 {
		margin: 0 0 0.25rem;
	}
	.barra p {
		margin: 0 0 0.5rem;
		font-size: 0.9rem;
		color: var(--tinta-suave);
	}
	.apunta code {
		font-size: 0.85rem;
		background: #ece8de;
		padding: 0.1rem 0.35rem;
		border-radius: 4px;
	}
	.filtros {
		display: flex;
		align-items: center;
		gap: 1rem;
		margin: 1rem 0 0.5rem;
		font-size: 0.85rem;
	}
	.cuenta {
		color: var(--tinta-suave);
	}
	button.enlace {
		background: none;
		border: none;
		padding: 0;
		font: inherit;
		font-size: 0.85rem;
		color: var(--verde-oscuro);
		text-decoration: underline;
		cursor: pointer;
	}
	.lista {
		list-style: none;
		padding: 0;
		margin: 0 0 1.25rem;
		columns: 2;
		font-size: 0.9rem;
	}
	.lista label {
		display: flex;
		align-items: center;
		gap: 0.4rem;
		padding: 0.2rem 0;
	}
	.suave {
		color: var(--tinta-suave);
		font-size: 0.85rem;
	}
	.consejo {
		margin-top: 0.75rem;
		font-size: 0.8rem;
	}

	.hoja {
		display: none;
	}
	.chapita {
		text-align: center;
		padding: 14px 12px;
		border: 1.5px dashed #c9c3b6;
		border-radius: 14px;
		break-inside: avoid;
	}
	.chapita img,
	.hueco {
		width: 62%;
		max-width: 200px;
		aspect-ratio: 1;
		display: block;
		margin: 8px auto 6px;
	}
	.hueco {
		background: #f0ece2;
		border-radius: 6px;
	}
	.marca {
		font-weight: 800;
		font-size: 12px;
		color: var(--verde-oscuro);
	}
	.nombre {
		font-weight: 800;
		font-size: 19px;
		margin-top: 2px;
	}
	.gancho {
		font-size: 13px;
		font-weight: 600;
		margin: 2px 0 4px;
	}
	.pie {
		font-size: 10px;
		color: var(--tinta-suave);
	}

	@media print {
		.barra {
			display: none;
		}
		.hoja {
			display: grid;
			grid-template-columns: 1fr 1fr;
			gap: 8px;
		}
		@page {
			margin: 12mm;
		}
	}
</style>
