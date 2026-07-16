<script lang="ts">
	import {
		bloquesArbol,
		bloquesSegunEstado,
		proyectar,
		sombra,
		ANCHO,
		ALTO,
		VERTICAL,
		VIEW_BOX
	} from '$lib/domain/arbol-voxel';
	import type { Estado } from '$lib/domain/estado';

	interface Props {
		estado?: Estado;
		/** Salud cruda 0..1. Pisa a `estado`: sirve para animar el árbol creciendo. */
		salud?: number;
		px?: number;
		/** Texto para lectores de pantalla; sin esto el árbol es un dibujo mudo. */
		alt?: string;
	}

	let { estado, salud, px = 120, alt }: Props = $props();

	const bloques = $derived(
		salud !== undefined ? bloquesArbol(salud) : bloquesSegunEstado(estado ?? 'muy_sediento')
	);

	// Las tres caras de cada cubo. La de arriba va plena y las laterales
	// oscurecidas: eso es todo lo que hace falta para que se vea el volumen.
	function caras(b: (typeof bloques)[number]) {
		const { cx, cy } = proyectar(b);
		return {
			arriba: `M${cx} ${cy - ALTO} L${cx + ANCHO} ${cy} L${cx} ${cy + ALTO} L${cx - ANCHO} ${cy} Z`,
			izq: `M${cx - ANCHO} ${cy} L${cx} ${cy + ALTO} L${cx} ${cy + ALTO + VERTICAL} L${cx - ANCHO} ${cy + VERTICAL} Z`,
			der: `M${cx + ANCHO} ${cy} L${cx} ${cy + ALTO} L${cx} ${cy + ALTO + VERTICAL} L${cx + ANCHO} ${cy + VERTICAL} Z`
		};
	}
</script>

<svg
	viewBox={VIEW_BOX}
	width={px}
	height={px}
	role={alt ? 'img' : 'presentation'}
	aria-label={alt}
	aria-hidden={alt ? undefined : 'true'}
>
	{#each bloques as b, i (i)}
		{@const c = caras(b)}
		<path d={c.arriba} fill={b.cara} />
		<path d={c.izq} fill={sombra(b.lado, 0.72)} />
		<path d={c.der} fill={sombra(b.lado, 0.52)} />
	{/each}
</svg>

<style>
	svg {
		display: block;
		/* Sin esto el navegador suaviza los bordes y se pierde el pixel art. */
		shape-rendering: crispEdges;
	}
</style>
