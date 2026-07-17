<script lang="ts">
	import { onMount } from 'svelte';
	import { goto, invalidateAll } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { ESTADO_INFO, type Estado } from '$lib/domain/estado';
	import { distanciaMetros, formatearDistancia } from '$lib/domain/distancia';
	import { gps, seguirPosicion } from '$lib/geo.svelte';
	import { registrarRiego, type RiegoResultado } from '$lib/features/riego/registrarRiego';
	import PantallaRegando from '$lib/features/riego/PantallaRegando.svelte';
	import EscanerQr from '$lib/features/riego/EscanerQr.svelte';
	import { escaneadoReciente, registrarEscaneo } from '$lib/features/riego/escaneo.svelte';
	import { cargarPerfil } from '$lib/features/auth/sesion.svelte';
	import ArbolVoxel from '$lib/ui/ArbolVoxel.svelte';

	let { data } = $props();

	type Fase = 'ficha' | 'regando' | 'resultado';
	let fase: Fase = $state('ficha');
	let resultado: RiegoResultado | null = $state(null);
	let escaneando = $state(false);

	onMount(() => {
		// Acá el GPS no es un extra: es lo que decide si el riego cuenta, así que
		// se pide apenas se abre la ficha.
		seguirPosicion();
	});

	const arbol = $derived(data.arbol);
	const estado = $derived((arbol.estado ?? 'muy_sediento') as Estado);
	const info = $derived(ESTADO_INFO[estado]);
	const puntos = $derived(data.puntosPorEstado[estado] ?? 0);
	const tieneCoords = $derived(arbol.lat != null && arbol.lng != null);

	const distancia = $derived(
		gps.fix && tieneCoords
			? distanciaMetros(gps.fix.lat, gps.fix.lng, arbol.lat!, arbol.lng!)
			: null
	);
	const cerca = $derived(distancia !== null && distancia <= data.radioMetros);
	/** Sin coordenadas cargadas el servidor todavía no exige proximidad (BT-19). */
	const proximidadOk = $derived(cerca || !tieneCoords);
	// El corazón de la decisión 17: sin escanear la chapita de ESTE árbol, no se
	// riega. El GPS no alcanza — los jacarandás están a ~5m y no los distingue.
	const escaneado = $derived(escaneadoReciente(arbol.codigo!));
	const puedeRegar = $derived(escaneado && proximidadOk);

	function alEscanear(codigo: string) {
		escaneando = false;
		registrarEscaneo(codigo);
		// Si escaneó OTRA chapita, lo llevamos a ese árbol (ya reconocido).
		if (codigo !== arbol.codigo) goto(resolve('/arbol/[codigo]', { codigo }));
	}

	async function regue() {
		fase = 'regando';
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

	function cuando(dias: number | null): string {
		if (dias === null) return 'nunca';
		if (dias < 1) return 'hoy';
		const d = Math.floor(dias);
		return d === 1 ? 'ayer' : `hace ${d} días`;
	}
</script>

<svelte:head>
	<title>{arbol.nombre ?? arbol.especie_nombre} · Árboles Gigantes</title>
</svelte:head>

{#if escaneando}
	<EscanerQr onCodigo={alEscanear} onCancelar={() => (escaneando = false)} />
{/if}

{#if fase === 'ficha'}
	<a class="back" href={resolve('/')}>◀ VOLVER</a>

	<div class="hero">
		<div class="big">
			<ArbolVoxel {estado} px={150} alt="Árbol {info.etiqueta.toLowerCase()}" />
		</div>
		<h1>{arbol.nombre ?? arbol.especie_nombre}</h1>
		<div class="sci">{arbol.especie_cientifico}</div>
		<div class="sector">📍 {arbol.sector ?? 'la plaza'} · {arbol.codigo}</div>
	</div>

	{#if estado !== 'feliz'}
		<div class="statline">
			<p class="statmsg">
				{#if estado === 'bien'}
					Está <b class="ok">bien</b>: fue regado {cuando(arbol.dias_sin_riego)}.
				{:else if estado === 'sediento'}
					Está <b class="mal">sediento</b>: hace {Math.floor(arbol.dias_sin_riego ?? 0)} días que nadie
					lo riega.
				{:else}
					¡Está <b class="mal">muy sediento</b>!
					{#if arbol.dias_sin_riego === null}
						Todavía nadie lo regó.
					{:else}
						Hace {Math.floor(arbol.dias_sin_riego)} días que nadie lo riega.
					{/if}
				{/if}
			</p>
		</div>
	{/if}

	<!-- El anti-trampa contado como lo cuenta la demo: no es un candado, es el
	     árbol reconociéndote. Y el reconocimiento arranca al escanear la chapita
	     (decisión 17): sin eso, no hay botón de riego. -->
	{#if estado === 'feliz'}
		<div class="magic panel">
			{#if (arbol.lluvia_3d ?? 0) >= 3}
				<div class="mh">🌧️ LA LLUVIA LO REGÓ</div>
				<div class="mr">
					<span class="e">💧</span>Llovió {Math.round(arbol.lluvia_3d ?? 0)} mm estos días — el suelo
					tiene agua de sobra
				</div>
			{:else}
				<div class="mh">🌳 ESTE JACARANDÁ ESTÁ FELIZ</div>
				<div class="mr">
					<span class="e">💧</span>Fue regado {cuando(arbol.dias_sin_riego)} — ya tomó suficiente agua
				</div>
			{/if}
		</div>
		<p class="lockmsg">
			🚫 Regarlo de más no suma. <a href={resolve('/')}>Buscá uno sediento 👉</a>
		</p>
	{:else if !escaneado}
		<!-- No escaneó todavía: este es el gate que faltaba. -->
		<div class="magic panel fail">
			<div class="mh">🔒 PARA REGAR, ESCANEÁ SU CHAPITA</div>
			<div class="mr no">
				<span class="e">📷</span>El árbol te reconoce de cerca, con su QR — no a distancia
			</div>
		</div>
		<button class="btn wide" onclick={() => (escaneando = true)}>📷 ESCANEAR LA CHAPITA</button>
		<p class="lockmsg">Estás parado frente al árbol: apuntá la cámara a su chapita.</p>
	{:else if puedeRegar}
		<div class="magic panel">
			<span class="spark s1">✦</span>
			<span class="spark s2">✦</span>
			<span class="spark s3">✦</span>
			<span class="spark s4">✦</span>
			<div class="mh">✨ EL ÁRBOL TE RECONOCIÓ ✨</div>
			<div class="mr"><span class="e">🌳</span>Escaneaste su chapita: sabe que sos vos</div>
			{#if cerca}
				<div class="mr"><span class="e">📍</span>Y siente que estás a su lado</div>
			{/if}
		</div>
		<button class="btn green wide act" onclick={regue}>💧 YA REGUÉ ESTE ÁRBOL (+{puntos})</button>
		<p class="lockmsg">Tocá recién cuando terminaste de regarlo</p>
	{:else if distancia !== null}
		<div class="magic panel fail">
			<div class="mh">🔒 ESTE RIEGO NO CONTARÍA</div>
			<div class="mr"><span class="e">🌳</span>Escaneaste su chapita ✓</div>
			<div class="mr no">
				<span class="e">📍</span>Pero estás lejos (~{formatearDistancia(distancia)}) ✗
			</div>
		</div>
		<button class="btn red wide" disabled>💧 NO PODÉS DESDE ACÁ</button>
		<p class="lockmsg">Para que cuente tenés que estar al pie del árbol.</p>
	{:else}
		<div class="magic panel fail">
			<div class="mh">🔒 NECESITAMOS TU UBICACIÓN</div>
			<div class="mr no">
				<span class="e">📍</span>{gps.error === 'permiso'
					? 'El navegador no nos da tu ubicación'
					: 'Buscando dónde estás…'}
			</div>
		</div>
		<button class="btn ghost wide" onclick={seguirPosicion}>📍 DAR MI UBICACIÓN</button>
	{/if}

	<div class="card2 panel">
		<div class="row">
			<span class="k">Leyenda del árbol</span>
			<span class="v pronto">— pronto 🚩</span>
		</div>
	</div>
{:else if fase === 'regando'}
	<PantallaRegando segundos={data.duracionSegundos} />
{:else if resultado}
	{#if resultado.ok}
		<div class="resultado">
			<div class="big">
				<ArbolVoxel estado={(arbol.estado ?? 'feliz') as Estado} px={150} alt="El árbol regado" />
			</div>
			<h1>¡GRACIAS!</h1>
			<p class="puntos">+{resultado.puntos}</p>
			{#if resultado.estado_anterior === 'muy_sediento'}
				<p class="rescate">Era un rescate: este árbol te necesitaba de verdad.</p>
			{/if}

			{#each resultado.insignias_nuevas as insignia (insignia.id)}
				<div class="magic panel">
					<span class="spark s1">✦</span>
					<span class="spark s2">✦</span>
					<span class="spark s3">✦</span>
					<div class="mh">🎖 {insignia.nombre.toUpperCase()}</div>
					<p class="copy">{insignia.copy}</p>
				</div>
			{/each}

			{#if resultado.total_puntos === null}
				<div class="card2 panel">
					<p class="guardar">Tus puntos quedaron guardados solo en este teléfono.</p>
					<a class="cta" href={resolve('/entrar')}>GUARDALOS EN TU CUENTA ▶</a>
				</div>
			{:else}
				<p class="acumulado">Llevás {resultado.total_puntos} puntos</p>
			{/if}
			<a class="btn ghost wide" href={resolve('/')}>◀ VER OTRO ÁRBOL</a>
		</div>
	{:else}
		<div class="resultado">
			<h1>NO SE PUDO</h1>
			<div class="magic panel fail">
				{#if resultado.motivo === 'cooldown_arbol'}
					<div class="mh">💚 YA TOMÓ AGUA</div>
					<div class="mr">
						<span class="e">💧</span>Alguien lo regó hace poquito. Con los árboles jóvenes, mejor no
						ahogarlos.
					</div>
					<div class="mr no">
						<span class="e">🕐</span>Se puede volver a regar a las {horaLocal(
							resultado.proximo_riego
						)}
					</div>
				{:else if resultado.motivo === 'cooldown_vecino'}
					<div class="mh">💚 A ESTE YA LO REGASTE VOS</div>
					<div class="mr">
						<span class="e">🙌</span>¡Gracias! Dale una oportunidad a otro sediento.
					</div>
				{:else if resultado.motivo === 'lejos'}
					<div class="mh">🔒 ESTÁS LEJOS DEL ÁRBOL</div>
					<div class="mr no">
						<span class="e">📍</span>El riego se registra parado en la plaza, balde en mano.
					</div>
				{:else if resultado.motivo === 'sin_ubicacion'}
					<div class="mh">🔒 SIN UBICACIÓN NO CUENTA</div>
					<div class="mr no"><span class="e">📍</span>Activá el GPS y probá de nuevo.</div>
				{:else}
					<div class="mh">📡 NO PUDIMOS REGISTRARLO</div>
					<div class="mr no">
						<span class="e">🔌</span>¿Anda la conexión? Esperá un momento y probá de nuevo.
					</div>
				{/if}
			</div>
			<button class="btn ghost wide" onclick={() => (fase = 'ficha')}>◀ VOLVER AL ÁRBOL</button>
			<p class="lockmsg"><a href={resolve('/')}>Ver los que sí necesitan agua</a></p>
		</div>
	{/if}
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
	.hero {
		text-align: center;
		padding: 4px 0;
	}
	.big {
		width: 150px;
		margin: 0 auto;
		/* Sombra dura, sin desenfoque: lo apoya sobre el pasto sin romper el pixel art. */
		filter: drop-shadow(4px 6px 0 rgba(0, 0, 0, 0.18));
	}
	.hero h1 {
		font-size: 16px;
		/* La pixel se lee mejor en mayúsculas, y así lo hace la demo. */
		text-transform: uppercase;
		margin: 6px 0;
		color: #fff;
		text-shadow: 3px 3px 0 #000;
	}
	.sci {
		font-size: 16px;
		font-style: italic;
	}
	.sector {
		font-size: 15px;
		margin-top: 5px;
	}
	.statline {
		text-align: center;
		margin: 12px 0;
	}
	.statmsg {
		font-size: 19px;
		color: #1d3a12;
		margin: 0;
	}
	.statmsg b.ok {
		color: #8a5a10;
	}
	.statmsg b.mal {
		color: #a82c30;
	}

	/* El panel del reconocimiento: verde y latiendo cuando el riego va a contar,
	   rojo y quieto cuando no. */
	.magic {
		position: relative;
		overflow: hidden;
		padding: 13px 14px;
		margin: 10px 0;
		border-color: var(--feliz);
		box-shadow:
			inset 3px 3px 0 rgba(70, 195, 106, 0.25),
			inset -3px -3px 0 #14101f;
	}
	.magic:not(.fail) {
		animation: magicglow 1.6s steps(2) infinite;
	}
	.magic.fail {
		border-color: var(--sed);
		box-shadow:
			inset 3px 3px 0 rgba(229, 72, 77, 0.22),
			inset -3px -3px 0 #14101f;
		animation: none;
	}
	.magic .mh {
		position: relative;
		z-index: 2;
		font-family: var(--pixel);
		font-size: 9px;
		line-height: 1.5;
		color: var(--feliz);
		text-shadow: 2px 2px 0 #14401f;
		text-align: center;
		margin-bottom: 10px;
	}
	.magic:not(.fail) .mh {
		animation: twinkle 0.8s steps(2) infinite;
	}
	.magic.fail .mh {
		color: var(--sed);
		text-shadow: 2px 2px 0 #400f10;
	}
	.magic .mr {
		position: relative;
		z-index: 2;
		display: flex;
		gap: 11px;
		align-items: center;
		font-size: 16px;
		color: var(--ink);
		padding: 4px 0;
	}
	.magic .mr .e {
		font-size: 21px;
		width: 28px;
		text-align: center;
		flex: none;
	}
	.magic .mr.no {
		color: var(--dim);
	}
	.magic .spark {
		position: absolute;
		z-index: 1;
		color: var(--gold);
		font-size: 13px;
		opacity: 0;
		pointer-events: none;
		text-shadow: 0 0 5px var(--gold);
	}
	.magic .spark.s1 {
		top: 7px;
		left: 11px;
		animation: sparkle 1.5s steps(3) infinite;
	}
	.magic .spark.s2 {
		top: 40px;
		right: 14px;
		animation: sparkle 1.5s steps(3) 0.5s infinite;
	}
	.magic .spark.s3 {
		bottom: 10px;
		left: 42%;
		animation: sparkle 1.5s steps(3) 1s infinite;
	}
	.magic .spark.s4 {
		top: 12px;
		right: 44%;
		animation: sparkle 1.3s steps(3) 0.8s infinite;
	}
	@keyframes magicglow {
		0%,
		100% {
			box-shadow:
				inset 3px 3px 0 rgba(70, 195, 106, 0.25),
				inset -3px -3px 0 #14101f,
				0 0 0 rgba(70, 195, 106, 0);
		}
		50% {
			box-shadow:
				inset 3px 3px 0 rgba(70, 195, 106, 0.45),
				inset -3px -3px 0 #14101f,
				0 0 14px rgba(70, 195, 106, 0.5);
		}
	}
	@keyframes twinkle {
		0%,
		100% {
			filter: brightness(1);
		}
		50% {
			filter: brightness(1.55);
		}
	}
	@keyframes sparkle {
		0%,
		100% {
			opacity: 0;
			transform: scale(0.3);
		}
		50% {
			opacity: 1;
			transform: scale(1);
		}
	}

	/* El botón de regar late: es la acción de toda la pantalla. */
	:global(.btn.act) {
		font-size: 12px;
		padding: 20px 10px;
		box-shadow:
			inset 3px 3px 0 #7ee29a,
			inset -3px -3px 0 #2b9350,
			0 7px 0 #1c6437;
		animation: actpulse 1.3s steps(2) infinite;
	}
	:global(.btn.act:active) {
		transform: translateY(4px);
		box-shadow:
			inset 3px 3px 0 #7ee29a,
			inset -3px -3px 0 #2b9350,
			0 3px 0 #1c6437;
		animation: none;
	}
	@keyframes actpulse {
		0%,
		100% {
			filter: brightness(1);
		}
		50% {
			filter: brightness(1.14);
		}
	}
	:global(.btn.red) {
		background: var(--sed);
		box-shadow:
			inset 3px 3px 0 #ff8a8d,
			inset -3px -3px 0 #a82c30,
			0 5px 0 #7a2023;
	}

	.lockmsg {
		text-align: center;
		font-size: 16px;
		color: #2c4a1e;
		margin: 9px 4px 0;
	}
	.card2 {
		padding: 12px 14px;
		margin: 14px 0;
	}
	.card2 .row {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 7px 2px;
		font-size: 17px;
	}
	.card2 .k {
		color: var(--dim);
	}
	.card2 .v {
		color: #fff;
	}
	.pronto {
		color: var(--dim);
	}

	.resultado {
		text-align: center;
	}
	.resultado h1 {
		font-size: 16px;
		color: #fff;
		text-shadow: 3px 3px 0 #000;
		margin: 6px 0;
	}
	.puntos {
		font-family: var(--pixel);
		font-size: 30px;
		color: var(--gold);
		text-shadow: 3px 3px 0 #6b4d00;
		margin: 10px 0;
	}
	.rescate {
		font-size: 18px;
		color: #1d3a12;
	}
	.copy {
		position: relative;
		z-index: 2;
		font-style: italic;
		color: var(--ink);
		margin: 0;
	}
	.guardar {
		margin: 0 0 8px;
		color: var(--dim);
		font-size: 17px;
	}
	.cta {
		font-family: var(--pixel);
		font-size: 9px;
		color: var(--violet-l);
		text-decoration: none;
	}
	.acumulado {
		color: #1d3a12;
	}
	/* El link de "ver otro árbol" se ve y se toca como botón. */
	a.btn {
		text-decoration: none;
		margin-top: 14px;
	}
</style>
