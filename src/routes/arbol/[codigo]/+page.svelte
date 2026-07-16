<script lang="ts">
	import { onMount } from 'svelte';
	import { invalidateAll } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { ESTADO_INFO, type Estado } from '$lib/domain/estado';
	import { distanciaMetros, formatearDistancia } from '$lib/domain/distancia';
	import { gps, seguirPosicion, quiereDistancias } from '$lib/geo.svelte';
	import { registrarRiego, type RiegoResultado } from '$lib/features/riego/registrarRiego';
	import { tipAlAzar } from '$lib/features/riego/tips';
	import { cargarPerfil } from '$lib/features/auth/sesion.svelte';
	import ArbolVoxel from '$lib/ui/ArbolVoxel.svelte';

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
		// El riego cambió el estado del árbol y, si hay sesión, los puntos del
		// vecino: hay que refrescar los dos o el header queda con el total viejo.
		if (res.ok) await Promise.all([invalidateAll(), cargarPerfil()]);
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
	<p class="volver"><a href={resolve('/')}>◀ volver</a></p>

	<div class="retrato">
		<div class="arbol">
			<ArbolVoxel
				estado={(arbol.estado ?? 'muy_sediento') as Estado}
				px={180}
				alt="Árbol {info.etiqueta.toLowerCase()}"
			/>
		</div>
		<h1>{arbol.nombre ?? arbol.especie_nombre}</h1>
		<p class="especie">
			{#if arbol.nombre}{arbol.especie_nombre} ·
			{/if}<em>{arbol.especie_cientifico}</em>
		</p>
		<p class="sector">📍 {arbol.sector ?? 'la plaza'} · {arbol.codigo}</p>
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

	<button class="btn green wide" onclick={regue}>💧 Regué este árbol</button>
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
			<!-- Ya regado: se lo ve como quedó, no como estaba. Es el premio visual. -->
			<div class="arbol">
				<ArbolVoxel estado={(arbol.estado ?? 'feliz') as Estado} px={180} alt="El árbol regado" />
			</div>
			<h1>¡Riego registrado!</h1>
			<p class="puntos">+{resultado.puntos} puntos</p>
			{#if resultado.estado_anterior === 'muy_sediento'}
				<p>Era un rescate: este árbol te necesitaba de verdad.</p>
			{/if}
			{#each resultado.insignias_nuevas as insignia (insignia.id)}
				<div class="insignia panel">
					<h2>🎖 {insignia.nombre}</h2>
					<p class="copy">{insignia.copy}</p>
				</div>
			{/each}
			{#if resultado.total_puntos === null}
				<div class="guardar panel">
					<p>Tus puntos quedaron guardados solo en este teléfono.</p>
					<a class="cta" href={resolve('/entrar')}>Guardalos en tu cuenta →</a>
				</div>
			{:else}
				<p class="acumulado">Llevás {resultado.total_puntos} puntos</p>
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
			<button class="btn ghost wide" onclick={() => (fase = 'ficha')}>Volver al árbol</button>
		</div>
	{/if}
{/if}

<style>
	.volver {
		font-family: var(--pixel);
		font-size: 9px;
		margin: 12px 0 4px;
	}
	.volver a {
		text-decoration: none;
	}
	.retrato {
		text-align: center;
		padding: 4px 0;
	}
	.arbol {
		display: flex;
		justify-content: center;
		/* La sombra dura, sin desenfoque, lo apoya sobre el pasto sin romper el
		   pixel art. */
		filter: drop-shadow(4px 6px 0 rgba(0, 0, 0, 0.18));
	}
	.retrato h1 {
		font-size: 16px;
		margin: 6px 0;
		color: #fff;
		text-shadow: 3px 3px 0 #000;
	}
	.especie {
		font-style: italic;
		margin: 0;
	}
	.sector {
		font-size: 15px;
		margin: 5px 0 0;
	}
	.estado {
		text-align: center;
		font-family: var(--pixel);
		font-size: 13px;
		margin: 14px 0 0;
	}
	.dias {
		text-align: center;
		color: #1d3a12;
		margin: 6px 0 14px;
	}
	.distancia {
		text-align: center;
		margin: 0 0 14px;
	}
	.aviso {
		font-size: 16px;
		text-align: center;
		margin: 14px 4px 0;
	}
	button.enlace {
		background: none;
		border: none;
		padding: 0;
		font: inherit;
		color: var(--violet-d);
		text-decoration: underline;
		cursor: pointer;
	}

	.regando {
		text-align: center;
		margin-top: 3rem;
	}
	.regando h1 {
		font-size: 18px;
		color: #fff;
		text-shadow: 3px 3px 0 #000;
	}
	.barra {
		height: 20px;
		background: var(--panel2);
		border: 3px solid var(--edge-d);
		overflow: hidden;
		margin: 20px 0;
	}
	.progreso {
		height: 100%;
		width: 0;
		background: var(--water);
		box-shadow: inset 0 3px 0 #8fd0fb;
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
		max-width: 34ch;
		margin: 0 auto;
	}

	.resultado {
		text-align: center;
		margin-top: 1rem;
	}
	.resultado h1 {
		font-size: 15px;
		color: #fff;
		text-shadow: 3px 3px 0 #000;
	}
	.puntos {
		font-family: var(--pixel);
		font-size: 26px;
		color: var(--gold);
		text-shadow: 3px 3px 0 #6b4d00;
		margin: 10px 0;
	}
	.insignia {
		margin: 2rem 0;
		padding: 14px;
	}
	.insignia h2 {
		margin: 0;
		color: var(--gold);
	}
	.copy {
		font-style: italic;
		max-width: 36ch;
		margin: 8px auto 0;
		color: var(--ink);
	}
	.guardar {
		margin: 1.5rem 0;
		padding: 14px;
	}
	.guardar p {
		margin: 0 0 8px;
		color: var(--dim);
		font-size: 17px;
	}
	.cta {
		font-family: var(--pixel);
		font-size: 9px;
		color: var(--violet-l);
	}
	.acumulado {
		color: #1d3a12;
	}
</style>
