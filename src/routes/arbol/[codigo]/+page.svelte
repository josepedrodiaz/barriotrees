<script lang="ts">
	import { onMount } from 'svelte';
	import { invalidateAll } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { ESTADO_INFO, type Estado } from '$lib/domain/estado';
	import { distanciaMetros, formatearDistancia } from '$lib/domain/distancia';
	import { gps, seguirPosicion, quiereDistancias } from '$lib/geo.svelte';
	import { registrarRiego, type RiegoResultado } from '$lib/features/riego/registrarRiego';
	import { tipAlAzar } from '$lib/features/riego/tips';

	let { data } = $props();

	onMount(() => {
		if (quiereDistancias()) seguirPosicion();
	});

	type Fase = 'ficha' | 'regando' | 'resultado';
	let fase: Fase = $state('ficha');
	let tip = $state('');
	let resultado: RiegoResultado | null = $state(null);

	const arbol = $derived(data.arbol);
	const info = $derived(ESTADO_INFO[(arbol.estado ?? 'muy_sediento') as Estado]);
	const distancia = $derived(
		gps.fix && arbol.lat != null && arbol.lng != null
			? distanciaMetros(gps.fix.lat, gps.fix.lng, arbol.lat, arbol.lng)
			: null
	);

	async function regue() {
		fase = 'regando';
		tip = tipAlAzar();
		// La espera mínima corre en paralelo con la geolocalización + la RPC:
		// el riego se registra recién cuando ambas terminan (decisión 19).
		const espera = new Promise((r) => setTimeout(r, data.duracionSegundos * 1000));
		const [res] = await Promise.all([registrarRiego(arbol.codigo!), espera]);
		resultado = res;
		fase = 'resultado';
		if (res.ok) await invalidateAll();
	}

	function horaLocal(iso: string | undefined): string {
		if (!iso) return '';
		return new Date(iso).toLocaleTimeString('es-AR', { hour: '2-digit', minute: '2-digit' });
	}

	function diasTexto(dias: number | null): string {
		if (dias === null) return 'Nunca lo regaron';
		if (dias < 1) return 'Regado hoy';
		const d = Math.floor(dias);
		return d === 1 ? 'Hace 1 día que no lo riegan' : `Hace ${d} días que no lo riegan`;
	}
</script>

<svelte:head>
	<title>{arbol.nombre ?? arbol.especie_nombre} · Árboles Gigantes</title>
</svelte:head>

{#if fase === 'ficha'}
	<p class="volver"><a href={resolve('/')}>← todos los árboles</a></p>

	<div class="retrato">
		<span class="arbol-emoji">{info.emoji}</span>
		<h1>{arbol.nombre ?? arbol.especie_nombre}</h1>
		<p class="especie">
			{#if arbol.nombre}{arbol.especie_nombre} ·
			{/if}<em>{arbol.especie_cientifico}</em> · {arbol.codigo}
		</p>
	</div>

	<p class="estado {info.clase}">{info.etiqueta}</p>
	<p class="dias">{diasTexto(arbol.dias_sin_riego)}</p>

	{#if distancia !== null}
		<p class="distancia">
			📍 Estás a {formatearDistancia(distancia)}{#if distancia <= 50}
				— al lado, ¡dale agua!{/if}
		</p>
	{:else if arbol.lat != null && !gps.siguiendo && !gps.error}
		<p class="distancia">
			<button class="enlace" onclick={seguirPosicion}>📍 Ver a qué distancia estás</button>
		</p>
	{/if}

	<button class="primario" onclick={regue}>💧 Regué este árbol</button>
	<p class="aviso">
		Contá solo riegos de verdad: el juego valida que estés en la plaza, y el árbol te lo agradece
		él.
	</p>
{:else if fase === 'regando'}
	<div class="regando">
		<h1>Regando…</h1>
		<div class="barra">
			<div class="progreso" style="animation-duration: {data.duracionSegundos}s"></div>
		</div>
		<p class="tip">🌱 {tip}</p>
	</div>
{:else if resultado}
	{#if resultado.ok}
		<div class="resultado">
			<span class="arbol-emoji">🌳</span>
			<h1>¡Riego registrado!</h1>
			<p class="puntos">+{resultado.puntos} puntos</p>
			{#if resultado.estado_anterior === 'muy_sediento'}
				<p>Era un rescate: este árbol te necesitaba de verdad.</p>
			{/if}
			{#each resultado.insignias_nuevas as insignia (insignia.id)}
				<div class="insignia">
					<h2>🎖 {insignia.nombre}</h2>
					<p class="copy">{insignia.copy}</p>
				</div>
			{/each}
			{#if resultado.total_puntos === null}
				<p class="guardar">
					Tus puntos quedaron guardados en este teléfono. Pronto vas a poder crear tu cuenta para no
					perderlos nunca.
				</p>
			{/if}
			<p><a href={resolve('/')}>Ver qué otro árbol necesita agua →</a></p>
		</div>
	{:else}
		<div class="resultado">
			<h1>Mmm, este riego no se pudo registrar</h1>
			{#if resultado.motivo === 'cooldown_arbol'}
				<p>
					Este árbol ya recibió agua hace poquito 💚 Con los árboles jóvenes, mejor no ahogarlos. Se
					puede volver a regar a las {horaLocal(resultado.proximo_riego)}.
				</p>
				<p><a href={resolve('/')}>Hay otros que sí te necesitan →</a></p>
			{:else if resultado.motivo === 'cooldown_vecino'}
				<p>A este ya lo regaste vos hace poco. ¡Gracias! Dale una oportunidad a otro sediento.</p>
				<p><a href={resolve('/')}>Ver los más sedientos →</a></p>
			{:else if resultado.motivo === 'lejos'}
				<p>
					Parece que no estás al lado del árbol{#if resultado.distancia_m}
						(a unos {resultado.distancia_m} m){/if}. El riego se registra parado en la plaza, balde
					en mano.
				</p>
			{:else if resultado.motivo === 'sin_ubicacion'}
				<p>
					Necesitamos tu ubicación para confirmar que estás en la plaza. Activá el GPS y volvé a
					intentar.
				</p>
			{:else}
				<p>No pudimos registrarlo (¿anda la conexión?). Esperá un momento y probá de nuevo.</p>
			{/if}
			<button class="primario" onclick={() => (fase = 'ficha')}>Volver al árbol</button>
		</div>
	{/if}
{/if}

<style>
	.volver {
		margin: 0 0 1.5rem;
	}
	.retrato {
		text-align: center;
		margin-top: 1rem;
	}
	.arbol-emoji {
		font-size: 4.5rem;
		display: block;
	}
	.retrato h1 {
		margin: 0.5rem 0 0;
	}
	.especie {
		color: var(--tinta-suave);
		margin: 0.25rem 0 0;
	}
	.estado {
		text-align: center;
		font-size: 1.5rem;
		font-weight: 750;
		margin: 2rem 0 0;
	}
	.dias {
		text-align: center;
		color: var(--tinta-suave);
		margin: 0.25rem 0 2rem;
	}
	.distancia {
		text-align: center;
		margin: -1rem 0 1.5rem;
	}
	button.enlace {
		background: none;
		border: none;
		padding: 0;
		font: inherit;
		font-size: 0.95rem;
		color: var(--verde-oscuro);
		text-decoration: underline;
		cursor: pointer;
	}
	.aviso {
		font-size: 0.85rem;
		color: var(--tinta-suave);
		text-align: center;
	}
	.regando {
		text-align: center;
		margin-top: 4rem;
	}
	.barra {
		height: 10px;
		background: #e8e4da;
		border-radius: 5px;
		overflow: hidden;
		margin: 2rem 0;
	}
	.progreso {
		height: 100%;
		width: 0;
		background: var(--verde);
		animation-name: llenar;
		animation-timing-function: linear;
		animation-fill-mode: forwards;
	}
	@keyframes llenar {
		to {
			width: 100%;
		}
	}
	.tip {
		font-size: 1.05rem;
		max-width: 34ch;
		margin: 0 auto;
	}
	.resultado {
		text-align: center;
		margin-top: 3rem;
	}
	.puntos {
		font-size: 2.5rem;
		font-weight: 800;
		color: var(--verde);
		margin: 0.5rem 0;
	}
	.insignia {
		margin: 2.5rem 0;
	}
	.insignia h2 {
		margin: 0;
	}
	.copy {
		font-size: 1.1rem;
		font-style: italic;
		max-width: 36ch;
		margin: 0.5rem auto 0;
	}
	.guardar {
		font-size: 0.9rem;
		color: var(--tinta-suave);
	}
</style>
