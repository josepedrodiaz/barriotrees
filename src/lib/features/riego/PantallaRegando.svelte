<script lang="ts">
	import { onMount } from 'svelte';
	import ArbolVoxel from '$lib/ui/ArbolVoxel.svelte';
	import { tipAlAzar, otroTip } from './tips';

	interface Props {
		segundos: number;
	}
	let { segundos }: Props = $props();

	// El árbol arranca marchito y florece mientras el vecino espera: la espera
	// mínima del anti-trampa (decisión 19) es, además, el premio. Es lo mejor de
	// la demo y lo que hace que estos segundos no se sientan un castigo.
	const SALUD_INICIAL = 0.16;
	let salud = $state(SALUD_INICIAL);
	let tip = $state(tipAlAzar());
	let entrando = $state(0);

	onMount(() => {
		const paso = 500;
		const crecer = setInterval(() => {
			salud = Math.min(1, salud + (1 - SALUD_INICIAL) / ((segundos * 1000) / paso));
		}, paso);
		const rotar = setInterval(() => {
			tip = otroTip(tip);
			entrando++;
		}, 5200);
		return () => {
			clearInterval(crecer);
			clearInterval(rotar);
		};
	});
</script>

<div class="wtr">
	<div class="caja">
		<div class="arbol">
			<ArbolVoxel {salud} px={150} alt="El árbol creciendo mientras lo regás" />
		</div>
		<div class="titulo">GUARDANDO TU RIEGO</div>
		<div class="gotas">💧 💧 💧</div>
		<div class="barra"><i style="animation-duration: {segundos}s"></i></div>
		<div class="dialogo">
			<div class="quien">SABÍAS QUE…</div>
			{#key entrando}
				<p class="tip">{tip}</p>
			{/key}
		</div>
		<p class="nota">Ya lo regaste ✓ — dale un segundo, lo estamos guardando 💧</p>
	</div>
</div>

<style>
	/* Tapa toda la app: el mundo se apaga y quedan el árbol y el agua. */
	.wtr {
		position: fixed;
		inset: 0;
		z-index: 60;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 22px;
		background: linear-gradient(180deg, #1a2740, #0e1826);
	}
	.caja {
		text-align: center;
		max-width: 360px;
		width: 100%;
	}
	.arbol {
		width: 150px;
		margin: 0 auto 8px;
	}
	.titulo {
		font-family: var(--pixel);
		font-size: 14px;
		color: var(--water);
		text-shadow: 2px 2px 0 #0a2c4a;
	}
	.gotas {
		height: 20px;
		margin: 8px 0 14px;
		font-size: 18px;
		letter-spacing: 6px;
		color: var(--water);
	}
	.barra {
		height: 20px;
		background: #0c1524;
		border: 3px solid #000;
		padding: 2px;
	}
	.barra i {
		display: block;
		height: 100%;
		width: 0;
		background: repeating-linear-gradient(90deg, var(--water) 0 8px, #2b86cc 8px 10px);
		animation-name: llenar;
		/* En escalones, no suave: el agua sube de a bloques, como todo acá. */
		animation-timing-function: steps(28);
		animation-fill-mode: forwards;
	}
	@keyframes llenar {
		to {
			width: 100%;
		}
	}
	.dialogo {
		margin-top: 18px;
		padding: 14px;
		background: var(--panel);
		border: 3px solid #000;
		box-shadow:
			inset 3px 3px 0 var(--edge-l),
			inset -3px -3px 0 #14101f;
	}
	.quien {
		font-family: var(--pixel);
		font-size: 8px;
		color: var(--feliz);
		margin-bottom: 8px;
	}
	.tip {
		font-size: 19px;
		min-height: 48px;
		color: var(--ink);
		margin: 0;
		animation: tipin 0.35s steps(3);
	}
	@keyframes tipin {
		from {
			opacity: 0.15;
		}
	}
	.nota {
		font-size: 15px;
		color: var(--dim);
		margin-top: 14px;
	}
</style>
