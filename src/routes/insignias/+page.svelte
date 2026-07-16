<script lang="ts">
	import { resolve } from '$app/paths';
	import { supabase } from '$lib/supabase';
	import { sesion } from '$lib/features/auth/sesion.svelte';
	import { progresoEscalera, gano, type Escalon } from '$lib/domain/insignias';

	let { data } = $props();

	interface Ganada {
		insignia_id: string;
		ganada_en: string;
		canje_estado: string;
	}

	let ganadas: Ganada[] = $state([]);
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
		const [{ data: g }, { data: progreso }] = await Promise.all([
			supabase
				.from('insignias_ganadas')
				.select('insignia_id, ganada_en, canje_estado')
				.eq('perfil_id', id),
			supabase.rpc('mi_progreso')
		]);
		ganadas = g ?? [];
		const p = progreso as { ok?: boolean; conteos?: Record<string, number> } | null;
		if (p?.ok) conteos = p.conteos ?? {};
	}

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

<p class="volver"><a href={resolve('/')}>← los árboles</a></p>

{#if sesion.session}
	<h1>Tus insignias</h1>
	<p class="puntaje"><strong>{nro(puntos)}</strong> puntos</p>

	{#if progreso.siguiente}
		<div class="camino">
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

<h2>La escalera</h2>
<p class="bajada">Siete peldaños por puntos acumulados. El primero se gana con el primer riego.</p>

<ol class="escalera">
	{#each escalera as escalon (escalon.id)}
		{@const ganada = gano(ganadas, escalon.id)}
		{@const proxima = progreso.siguiente?.id === escalon.id}
		<li class:ganada class:proxima>
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

<h2>Por cómo cuidás</h2>
<p class="bajada">Estas no dependen de cuánto sumás, sino de qué hacés.</p>

<ul class="meritos">
	{#each data.meritos as merito (merito.id)}
		{@const ganada = gano(ganadas, merito.id)}
		{@const objetivo = objetivoDe(merito.criterio)}
		{@const actual = Math.min(actualDe(merito.criterio), objetivo)}
		<li class:ganada>
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

{#if ganadas.some((g) => g.canje_estado === 'pendiente')}
	<p class="pines">
		🎖 Tenés {ganadas.filter((g) => g.canje_estado === 'pendiente').length} pin{ganadas.filter(
			(g) => g.canje_estado === 'pendiente'
		).length === 1
			? ''
			: 'es'} esperándote. Te los entrega la comisión en mano.
	</p>
{/if}

<style>
	.volver {
		margin: 0 0 1rem;
	}
	h1 {
		margin: 0;
	}
	.puntaje {
		margin: 0.25rem 0 1.5rem;
		font-size: 1.1rem;
		color: var(--tinta-suave);
	}
	.puntaje strong {
		font-size: 2.5rem;
		color: var(--verde);
	}
	.intro {
		color: var(--tinta-suave);
	}
	.cta {
		font-weight: 700;
	}
	.camino {
		margin: 0 0 2.5rem;
	}
	.camino p {
		margin: 0.5rem 0 0;
		font-size: 0.95rem;
		color: var(--tinta-suave);
	}
	.cumbre {
		font-style: italic;
	}
	.barra {
		height: 8px;
		background: #e8e4da;
		border-radius: 4px;
		overflow: hidden;
	}
	.avance {
		height: 100%;
		background: var(--verde);
		transition: width 0.4s ease;
	}
	h2 {
		margin: 2.5rem 0 0.25rem;
		font-size: 1.15rem;
	}
	.bajada {
		margin: 0 0 1.25rem;
		font-size: 0.9rem;
		color: var(--tinta-suave);
	}
	.escalera,
	.meritos {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.escalera li,
	.meritos li {
		display: flex;
		gap: 0.85rem;
		padding: 0.9rem 0;
		border-bottom: 1px solid #ece8de;
		opacity: 0.45;
	}
	.escalera li.ganada,
	.meritos li.ganada {
		opacity: 1;
	}
	.escalera li.proxima {
		opacity: 0.8;
	}
	.marca {
		width: 1.6rem;
		flex: none;
		text-align: center;
		font-size: 1.2rem;
		font-variant-numeric: tabular-nums;
		color: var(--tinta-suave);
	}
	.ganada .marca {
		color: inherit;
	}
	.cuerpo {
		min-width: 0;
	}
	h3 {
		margin: 0;
		font-size: 1.05rem;
		font-weight: 700;
	}
	.ganada h3 {
		color: var(--verde-oscuro);
	}
	.copy {
		margin: 0.35rem 0 0;
		font-style: italic;
		font-size: 0.95rem;
	}
	.umbral {
		margin: 0.15rem 0 0;
		font-size: 0.8rem;
		color: var(--tinta-suave);
		font-variant-numeric: tabular-nums;
	}
	.pines {
		margin-top: 2rem;
		font-size: 0.9rem;
		color: var(--tinta-suave);
	}
</style>
