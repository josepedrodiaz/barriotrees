<script lang="ts">
	// La bienvenida de 3 pasos (decisión 14 + BT-20). Es fundamental: el que
	// escanea una chapita en la plaza llega en frío, sin saber qué es esto ni
	// qué se espera de él. Estos tres pasos son todo el onboarding del proyecto.
	// Portada de tools/demo.html (welcomeModal), paso por paso.
	import Pin from '$lib/ui/Pin.svelte';
	import BroteEnMano from '$lib/ui/BroteEnMano.svelte';
	import { cerrarBienvenida } from './vista.svelte';

	interface Props {
		/** Nombre del árbol si llegó escaneando su chapita; si no, no hay árbol. */
		arbol?: string;
	}
	let { arbol }: Props = $props();

	let paso = $state(1);
</script>

<div class="scrim">
	<div class="modal panel">
		{#if paso === 1}
			<div class="medal">🌳</div>
			<h3>LLEGASTE A</h3>
			<div class="name">ÁRBOLES GIGANTES</div>
			<p>Este es un juego del barrio para cuidar entre todos a los árboles y hacerlos crecer. 🌱</p>
			<div class="dots"><i class="on"></i><i></i><i></i></div>
			<button class="btn gold wide" onclick={() => (paso = 2)}>SIGUIENTE ▶</button>
		{:else if paso === 2}
			<div class="medal">💧</div>
			{#if arbol}
				<h3>ESCANEASTE</h3>
				<div class="name">{arbol.toUpperCase()}</div>
				<h3>TU MISIÓN AHORA ES</h3>
				<div class="name chico">REGAR ESTE ÁRBOL</div>
			{:else}
				<h3>TU MISIÓN ES</h3>
				<div class="name">REGAR UN ÁRBOL</div>
			{/if}
			<div class="wsteps">
				<div class="wstep">
					<span class="em">🪣</span>
					<span class="tx"><b>Llená el balde</b> en el bebedero de la plaza</span>
				</div>
				<div class="wstep">
					<span class="em">🌳</span>
					<span class="tx"
						><b>Regá</b> {arbol ? 'este arbolito' : 'un arbolito'} con el agua del balde</span
					>
				</div>
				<div class="wstep">
					<span class="em">⭐</span>
					<span class="tx">
						Cuando termines, tocá el botón <b>YA REGUÉ ESTE ÁRBOL</b>. Felicitaciones: ¡ya sumaste
						tus primeros puntos!
					</span>
				</div>
			</div>
			<div class="dots"><i></i><i class="on"></i><i></i></div>
			<button class="btn gold wide" onclick={() => (paso = 3)}>SIGUIENTE ▶</button>
		{:else}
			<div class="pinbadge"><Pin px={96} alt="El pin que se entrega en mano" /></div>
			<h3>REGÁS Y GANÁS</h3>
			<div class="name">INSIGNIAS EN LA VIDA REAL</div>
			<div class="wsteps">
				<div class="wstep">
					<span class="em"><BroteEnMano px={32} /></span>
					<span class="tx">
						Cuando <b>cuidás los árboles</b> sumás puntos para lograr tu próxima insignia
					</span>
				</div>
				<div class="wstep">
					<span class="em"><Pin px={26} /></span>
					<span class="tx">
						Cada insignia que ganes en el juego <b>te la damos en la vida real</b>
					</span>
				</div>
			</div>
			<div class="dots"><i></i><i></i><i class="on"></i></div>
			<button class="btn gold wide" onclick={cerrarBienvenida}>¡EMPEZAR! 🌱</button>
		{/if}
	</div>
</div>

<style>
	.scrim {
		position: fixed;
		inset: 0;
		background: rgba(8, 6, 16, 0.78);
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 24px;
		z-index: 80;
		overflow-y: auto;
	}
	.modal {
		max-width: 360px;
		width: 100%;
		padding: 24px 20px;
		text-align: center;
	}
	.medal {
		font-size: 56px;
		line-height: 1;
		animation: pixpop 0.5s steps(4);
	}
	.pinbadge {
		animation: pixpop 0.5s steps(4);
		margin: 2px auto;
	}
	@keyframes pixpop {
		from {
			transform: scale(0.2);
		}
		to {
			transform: scale(1);
		}
	}
	h3 {
		font-family: var(--pixel);
		font-size: 10px;
		color: var(--gold);
		margin: 14px 0 8px;
		text-shadow: 2px 2px 0 #6b4e08;
	}
	.name {
		font-family: var(--pixel);
		font-size: 15px;
		line-height: 1.5;
		color: #fff;
		margin: 0 0 12px;
		text-shadow: 2px 2px 0 #000;
	}
	.name.chico {
		font-size: 12px;
	}
	p {
		font-size: 19px;
		color: var(--ink);
		margin: 0 0 10px;
		line-height: 1.3;
	}
	.dots {
		display: flex;
		gap: 8px;
		justify-content: center;
		margin: 4px 0 14px;
	}
	.dots i {
		width: 9px;
		height: 9px;
		background: #4a4066;
		display: inline-block;
	}
	.dots i.on {
		background: var(--gold);
		box-shadow: inset 2px 2px 0 #ffe08a;
	}
	.wsteps {
		display: flex;
		flex-direction: column;
		gap: 12px;
		text-align: left;
		margin: 6px 2px 18px;
	}
	.wstep {
		display: flex;
		align-items: center;
		gap: 13px;
	}
	.wstep .em {
		font-size: 30px;
		width: 42px;
		height: 42px;
		flex: none;
		display: flex;
		align-items: center;
		justify-content: center;
		background: var(--panel2);
		border: 3px solid var(--edge-d);
		box-shadow: inset 2px 2px 0 var(--edge-l);
	}
	.wstep .tx {
		font-size: 18px;
		color: var(--dim);
		line-height: 1.25;
	}
	.wstep .tx b {
		color: var(--ink);
	}
	@media (prefers-reduced-motion: reduce) {
		.medal,
		.pinbadge {
			animation: none;
		}
	}
</style>
