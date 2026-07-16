<script lang="ts">
	import { resolve } from '$app/paths';
	import { supabase } from '$lib/supabase';
	import { sesion } from '$lib/features/auth/sesion.svelte';
	import { progresoEscalera, type Escalon } from '$lib/domain/insignias';

	interface Props {
		escalera: Escalon[];
	}
	let { escalera }: Props = $props();

	let ganadas: { insignia_id: string; nombre: string }[] = $state([]);
	let cargadoPara: string | null = $state(null);

	$effect(() => {
		const id = sesion.session?.user.id;
		if (sesion.cargando || !id || cargadoPara === id) return;
		cargadoPara = id;
		supabase
			.from('insignias_ganadas')
			.select('insignia_id, insignias(nombre)')
			.eq('perfil_id', id)
			.then(({ data }) => {
				ganadas = (data ?? []).map((g) => ({
					insignia_id: g.insignia_id,
					nombre: (g.insignias as { nombre: string } | null)?.nombre ?? g.insignia_id
				}));
			});
	});

	const puntos = $derived(sesion.perfil?.puntos ?? 0);
	const progreso = $derived(progresoEscalera(puntos, escalera));
	const nro = (n: number) => n.toLocaleString('es-AR');
</script>

<div class="me panel">
	{#if sesion.perfil}
		<div class="usr">🙋 {sesion.perfil.nombre}</div>
		<div class="lvl">NIVEL: {(progreso.actual?.nombre ?? 'Sin regar').toUpperCase()}</div>
		<div class="pts">{nro(puntos)} <small>PTS</small></div>
		<div class="xp"><i style="width: {progreso.porcentaje}%"></i></div>
		<div class="next">
			{#if progreso.siguiente}
				Faltan {nro(progreso.faltan)} para {progreso.siguiente.nombre.toUpperCase()}
			{:else}
				¡LLEGASTE A LO MÁS ALTO!
			{/if}
		</div>
		<div class="badges">
			{#each ganadas as g (g.insignia_id)}
				<a class="badge" href={resolve('/insignias')}>🎖 {g.nombre.toUpperCase()}</a>
			{:else}
				<a class="badge empty" href={resolve('/insignias')}>SIN LOGROS — REGÁ TU 1ER ÁRBOL</a>
			{/each}
		</div>
	{:else}
		<!-- Sin cuenta el vecino igual juega (decisión 14): esto no es un muro,
		     es la invitación a que lo suyo no se pierda. -->
		<div class="usr">🙋 Vecino sin cuenta</div>
		<div class="next sin">
			Podés regar igual. Creá tu cuenta cuando quieras y tus riegos se van con vos.
		</div>
		<div class="badges">
			<a class="badge empty" href={resolve('/entrar')}>ENTRAR Y GUARDAR MIS PUNTOS</a>
		</div>
	{/if}
</div>

<style>
	.me {
		padding: 14px;
	}
	.usr {
		font-family: var(--pixel);
		font-size: 12px;
		line-height: 1.5;
		color: #fff;
		text-shadow: 2px 2px 0 #000;
		margin-bottom: 10px;
	}
	.lvl {
		font-family: var(--pixel);
		font-size: 10px;
		line-height: 1.5;
		color: var(--gold);
		text-shadow: 2px 2px 0 #6b4e08;
	}
	.pts {
		font-family: var(--pixel);
		font-size: 22px;
		margin: 10px 0;
		color: #fff;
		text-shadow: 3px 3px 0 #000;
	}
	.pts small {
		font-family: var(--read);
		font-size: 18px;
		color: var(--dim);
	}
	/* La barra de experiencia sube a bloques, no suave. */
	.xp {
		height: 18px;
		background: #171225;
		border: 3px solid var(--edge-d);
		padding: 2px;
	}
	.xp i {
		display: block;
		height: 100%;
		background: repeating-linear-gradient(90deg, var(--feliz) 0 8px, #3bb35f 8px 10px);
		transition: width 0.5s steps(8);
	}
	.next {
		font-size: 17px;
		color: var(--dim);
		margin-top: 7px;
	}
	.next.sin {
		margin-top: 0;
	}
	.badges {
		display: flex;
		gap: 7px;
		margin-top: 12px;
		flex-wrap: wrap;
	}
	.badge {
		font-family: var(--pixel);
		font-size: 8px;
		line-height: 1.5;
		color: #3a2c00;
		background: var(--gold);
		border: 2px solid #8a6a10;
		padding: 6px 8px;
		display: inline-flex;
		gap: 5px;
		align-items: center;
		box-shadow: inset 2px 2px 0 #ffe08a;
		text-decoration: none;
	}
	.badge.empty {
		background: #3a3355;
		color: var(--dim);
		border-color: var(--edge-l);
		box-shadow: none;
	}
</style>
