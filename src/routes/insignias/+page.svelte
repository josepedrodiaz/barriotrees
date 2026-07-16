<script lang="ts">
	import { resolve } from '$app/paths';
	import { supabase } from '$lib/supabase';
	import { sesion, salir, cargarPerfil } from '$lib/features/auth/sesion.svelte';
	import { progresoEscalera, gano, type Escalon } from '$lib/domain/insignias';
	import QrDeCanje from '$lib/features/premios/QrDeCanje.svelte';

	let { data } = $props();

	// Editar el nombre (BT-26): así en el ranking no aparece el prefijo del mail.
	let editandoNombre = $state(false);
	let nombreNuevo = $state('');
	let guardandoNombre = $state(false);
	let errorNombre: string | null = $state(null);

	function abrirNombre() {
		nombreNuevo = sesion.perfil?.nombre ?? '';
		errorNombre = null;
		editandoNombre = true;
	}

	async function guardarNombre(evento: SubmitEvent) {
		evento.preventDefault();
		guardandoNombre = true;
		errorNombre = null;
		const { data: res } = await supabase.rpc('actualizar_mi_nombre', { p_nombre: nombreNuevo });
		guardandoNombre = false;
		const r = res as { ok?: boolean; motivo?: string } | null;
		if (r?.ok) {
			await cargarPerfil();
			editandoNombre = false;
		} else {
			errorNombre =
				r?.motivo === 'muy_corto'
					? 'Muy corto: al menos 2 letras.'
					: r?.motivo === 'muy_largo'
						? 'Muy largo: hasta 24 letras.'
						: 'No se pudo guardar. Probá de nuevo.';
		}
	}

	interface Ganada {
		insignia_id: string;
		ganada_en: string;
		canje_estado: string;
	}

	interface Canje {
		insignia_id: string;
		nombre: string;
		estado: string;
		token: string;
	}

	let ganadas: Ganada[] = $state([]);
	let canjes: Canje[] = $state([]);
	let conteos: Record<string, number> = $state({});
	let cargadoPara: string | null = $state(null);

	// Lo del vecino llega cuando la sesión está lista (el layout la restaura al
	// arrancar). Se recarga si cambia de cuenta.
	$effect(() => {
		const id = sesion.session?.user.id;
		if (sesion.cargando || !id || cargadoPara === id) return;
		cargadoPara = id;
		cargarMio(id);
	});

	async function cargarMio(id: string) {
		// Los tokens de canje no se leen de la tabla (son privados): los da una
		// RPC que solo devuelve los del vecino logueado.
		const [{ data: g }, { data: progreso }, { data: mis }] = await Promise.all([
			supabase
				.from('insignias_ganadas')
				.select('insignia_id, ganada_en, canje_estado')
				.eq('perfil_id', id),
			supabase.rpc('mi_progreso'),
			supabase.rpc('mis_canjes')
		]);
		ganadas = g ?? [];
		const p = progreso as { ok?: boolean; conteos?: Record<string, number> } | null;
		if (p?.ok) conteos = p.conteos ?? {};
		const c = mis as { ok?: boolean; canjes?: Canje[] } | null;
		if (c?.ok) canjes = c.canjes ?? [];
	}

	const pendientes = $derived(canjes.filter((c) => c.estado === 'pendiente'));
	const entregados = $derived(canjes.filter((c) => c.estado === 'entregado'));

	const puntos = $derived(sesion.perfil?.puntos ?? 0);
	const escalera = $derived(data.escalera as unknown as Escalon[]);
	const progreso = $derived(progresoEscalera(puntos, escalera));

	const nro = (n: number) => n.toLocaleString('es-AR');

	function objetivoDe(criterio: unknown): number {
		const c = criterio as { config_n?: string } | null;
		return c?.config_n ? (data.objetivos[c.config_n] ?? 0) : 0;
	}
	function actualDe(criterio: unknown): number {
		const c = criterio as { evento?: string } | null;
		return c?.evento ? (conteos[c.evento] ?? 0) : 0;
	}

	/** Qué hay que hacer para ganarla, en criollo. El nombre solo no alcanza. */
	function requisito(criterio: unknown): string {
		const c = criterio as { evento?: string } | null;
		const n = objetivoDe(criterio);
		switch (c?.evento) {
			case 'rescate':
				return `${n} riegos a árboles muy sedientos`;
			case 'madrugada':
				return `${n} riegos antes de las ${data.objetivos['madrugador_hora_limite']}`;
			case 'atardecer':
				return `${n} riegos después de las ${data.objetivos['sereno_hora_inicio']}`;
			case 'reporte_verificado':
				return `${n} reportes de peligro verificados`;
			default:
				return '';
		}
	}
</script>

<svelte:head>
	<title>Insignias · Árboles Gigantes</title>
</svelte:head>

<p class="volver"><a href={resolve('/')}>◀ volver</a></p>

{#if sesion.session}
	<div class="perfil">
		{#if editandoNombre}
			<form class="nombre-form" onsubmit={guardarNombre}>
				<input
					bind:value={nombreNuevo}
					maxlength="24"
					placeholder="Tu nombre en el juego"
					autocomplete="off"
				/>
				<div class="nombre-acciones">
					<button class="btn sm" type="submit" disabled={guardandoNombre}>
						{guardandoNombre ? '…' : 'Guardar'}
					</button>
					<button type="button" class="enlace" onclick={() => (editandoNombre = false)}
						>cancelar</button
					>
				</div>
				{#if errorNombre}<p class="error">{errorNombre}</p>{/if}
			</form>
		{:else}
			<h1>{sesion.perfil?.nombre}</h1>
			<button class="enlace" onclick={abrirNombre}>cambiar nombre</button>
		{/if}
	</div>
	<p class="puntaje"><strong>{nro(puntos)}</strong> puntos</p>

	{#if progreso.siguiente}
		<div class="camino panel">
			<div class="barra"><div class="avance" style="width: {progreso.porcentaje}%"></div></div>
			<p>
				Te faltan <strong>{nro(progreso.faltan)}</strong> para
				<strong>{progreso.siguiente.nombre}</strong>
			</p>
		</div>
	{:else if progreso.actual}
		<p class="camino cumbre">Llegaste a lo más alto. No queda nadie arriba tuyo.</p>
	{/if}
{:else}
	<h1>Insignias</h1>
	<p class="intro">
		Se ganan regando y no se pierden nunca. Cada una se entrega como un pin de verdad, hecho a mano
		por el barrio.
	</p>
	<p><a class="cta" href={resolve('/entrar')}>Entrá para empezar a ganarlas →</a></p>
{/if}

<h2 class="section-h">La escalera</h2>
<p class="bajada">Siete peldaños por puntos acumulados. El primero se gana con el primer riego.</p>

<ol class="escalera">
	{#each escalera as escalon (escalon.id)}
		{@const ganada = gano(ganadas, escalon.id)}
		{@const proxima = progreso.siguiente?.id === escalon.id}
		<li class="panel" class:ganada class:proxima>
			<span class="marca">{ganada ? '🎖' : escalon.orden}</span>
			<div class="cuerpo">
				<h3>{escalon.nombre}</h3>
				{#if ganada}
					<p class="copy">{data.escalera.find((e) => e.id === escalon.id)?.copy_desbloqueo}</p>
				{/if}
				<p class="umbral">
					{escalon.umbral_puntos === 1
						? 'con tu primer riego'
						: `${nro(escalon.umbral_puntos)} puntos`}
				</p>
			</div>
		</li>
	{/each}
</ol>

<h2 class="section-h">Por cómo cuidás</h2>
<p class="bajada">Estas no dependen de cuánto sumás, sino de qué hacés.</p>

<ul class="meritos">
	{#each data.meritos as merito (merito.id)}
		{@const ganada = gano(ganadas, merito.id)}
		{@const objetivo = objetivoDe(merito.criterio)}
		{@const actual = Math.min(actualDe(merito.criterio), objetivo)}
		<li class="panel" class:ganada>
			<span class="marca">{ganada ? '🎖' : '·'}</span>
			<div class="cuerpo">
				<h3>{merito.nombre}</h3>
				{#if ganada}
					<p class="copy">{merito.copy_desbloqueo}</p>
				{:else}
					<p class="umbral">
						{#if sesion.session && objetivo > 0}{actual} de
						{/if}{requisito(merito.criterio)}
					</p>
				{/if}
			</div>
		</li>
	{/each}
</ul>

{#if sesion.session}
	<p class="cuenta"><button class="salir" onclick={salir}>Cerrar sesión</button></p>
{/if}

{#if pendientes.length}
	<h2 class="section-h">
		{pendientes.length === 1
			? 'Tenés un pin esperándote'
			: `Tenés ${pendientes.length} pines esperándote`}
	</h2>
	<p class="bajada">
		Te los entrega la comisión en mano. Mostrá el QR y es tuyo — cada uno se canjea una sola vez.
	</p>
	{#each pendientes as c (c.insignia_id)}
		<QrDeCanje nombre={c.nombre} token={c.token} urlBase={data.urlBase} />
	{/each}
{/if}

{#if entregados.length}
	<p class="pines">
		🎖 Ya tenés en tu poder {entregados.length}
		{entregados.length === 1 ? 'pin' : 'pines'}: {entregados.map((c) => c.nombre).join(', ')}.
	</p>
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
	h1 {
		margin: 10px 0 0;
		text-align: center;
		color: #fff;
		text-shadow: 3px 3px 0 #000;
	}
	.perfil {
		text-align: center;
	}
	.perfil .enlace {
		font-size: 15px;
		color: var(--violet-l);
	}
	.nombre-form {
		max-width: 280px;
		margin: 10px auto 0;
	}
	.nombre-form input {
		width: 100%;
		padding: 10px;
		border: 3px solid var(--edge-d);
		background: var(--panel2);
		color: var(--ink);
		font: inherit;
		text-align: center;
		box-shadow: inset 3px 3px 0 #1a1528;
	}
	.nombre-acciones {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 12px;
		margin-top: 8px;
	}
	.error {
		color: var(--sed);
		font-size: 16px;
		text-align: center;
		margin: 8px 0 0;
	}
	.puntaje {
		margin: 8px 0 14px;
		text-align: center;
	}
	.puntaje strong {
		display: block;
		font-family: var(--pixel);
		font-size: 26px;
		font-weight: 400;
		color: var(--gold);
		text-shadow: 3px 3px 0 #6b4d00;
	}
	.intro {
		text-align: center;
		margin: 8px 4px;
	}
	.cta {
		font-family: var(--pixel);
		font-size: 9px;
	}
	.camino {
		padding: 12px 14px;
		margin: 0 0 6px;
	}
	.camino p {
		margin: 8px 0 0;
		font-size: 17px;
		color: var(--dim);
		text-align: center;
	}
	.cumbre {
		font-style: italic;
		text-align: center;
	}
	/* La barra de experiencia: hueco oscuro con relleno dorado, sin curvas. */
	.barra {
		height: 16px;
		background: var(--panel2);
		border: 2px solid var(--edge-d);
		overflow: hidden;
	}
	.avance {
		height: 100%;
		background: var(--gold);
		box-shadow: inset 0 2px 0 #ffe08a;
		transition: width 0.4s steps(12);
	}
	.bajada {
		margin: 0 4px 10px;
		font-size: 16px;
	}
	.escalera,
	.meritos {
		list-style: none;
		padding: 0;
		margin: 0;
		display: flex;
		flex-direction: column;
		gap: 8px;
	}
	.escalera li,
	.meritos li {
		display: flex;
		gap: 10px;
		align-items: center;
		padding: 10px;
		/* Las que todavía no ganó se ven apagadas, pero legibles: son la
		   zanahoria, no un secreto. */
		opacity: 0.55;
	}
	.escalera li.ganada,
	.meritos li.ganada {
		opacity: 1;
	}
	.escalera li.proxima {
		opacity: 0.85;
	}
	.marca {
		width: 2rem;
		flex: none;
		text-align: center;
		font-family: var(--pixel);
		font-size: 12px;
		color: var(--dim);
	}
	.cuerpo {
		min-width: 0;
	}
	h3 {
		margin: 0;
		color: #fff;
	}
	.ganada h3 {
		color: var(--gold);
	}
	.copy {
		margin: 6px 0 0;
		font-style: italic;
		color: var(--ink);
	}
	.umbral {
		margin: 4px 0 0;
		font-size: 16px;
		color: var(--dim);
	}
	.cuenta {
		text-align: center;
		margin-top: 24px;
	}
	.salir {
		font: inherit;
		background: none;
		border: none;
		color: var(--dim);
		text-decoration: underline;
		cursor: pointer;
	}
	.pines {
		margin-top: 16px;
		padding: 12px 14px;
		font-size: 17px;
		text-align: center;
	}
</style>
