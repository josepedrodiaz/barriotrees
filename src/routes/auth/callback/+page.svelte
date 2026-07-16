<script lang="ts">
	import { onMount } from 'svelte';
	import { resolve } from '$app/paths';
	import { supabase } from '$lib/supabase';
	import { cargarPerfil } from '$lib/features/auth/sesion.svelte';
	import { reclamarRiegos, type ReclamoResultado } from '$lib/features/auth/reclamo';

	type Fase = 'entrando' | 'listo' | 'error';
	let fase: Fase = $state('entrando');
	let reclamo: ReclamoResultado | null = $state(null);
	let nombre = $state('');

	onMount(async () => {
		// La sesión puede tardar un instante: supabase-js lee el token del hash
		// apenas carga y avisa por onAuthStateChange.
		const { data } = await supabase.auth.getSession();
		let sesionActiva = data.session;

		if (!sesionActiva) {
			sesionActiva = await new Promise((resolver) => {
				const { data: sub } = supabase.auth.onAuthStateChange((_e, s) => {
					if (s) {
						sub.subscription.unsubscribe();
						resolver(s);
					}
				});
				setTimeout(() => {
					sub.subscription.unsubscribe();
					resolver(null);
				}, 8000);
			});
		}

		if (!sesionActiva) {
			fase = 'error';
			return;
		}

		nombre = (sesionActiva.user.user_metadata?.full_name as string)?.split(' ')[0] ?? '';
		reclamo = await reclamarRiegos();
		await cargarPerfil();
		fase = 'listo';
	});
</script>

<svelte:head>
	<title>Entrando… · Árboles Gigantes</title>
</svelte:head>

{#if fase === 'entrando'}
	<div class="centro">
		<span class="emoji">🌱</span>
		<h1>Entrando…</h1>
	</div>
{:else if fase === 'error'}
	<div class="centro">
		<h1>No pudimos entrar</h1>
		<p>El link puede haber vencido o ya haberse usado.</p>
		<p><a href={resolve('/entrar')}>Probar de nuevo →</a></p>
	</div>
{:else if reclamo?.ok && reclamo.riegos > 0}
	<div class="centro">
		<span class="emoji">🎉</span>
		<h1>Listo{nombre ? `, ${nombre}` : ''}</h1>
		<p class="rescatado">
			{reclamo.riegos}
			{reclamo.riegos === 1 ? 'riego tuyo ahora tiene' : 'riegos tuyos ahora tienen'} dueño
		</p>
		<p class="puntos">+{reclamo.puntos} puntos</p>

		{#each reclamo.insignias_nuevas as insignia (insignia.id)}
			<div class="insignia">
				<h2>🎖 {insignia.nombre}</h2>
				<p class="copy">{insignia.copy}</p>
			</div>
		{/each}

		{#if reclamo.insignias_nuevas.length > 0}
			<p class="chico">
				Las insignias se entregan como pin de verdad. Guardalas: te las va a dar la comisión.
			</p>
		{/if}

		<p><a href={resolve('/')}>Ver los árboles sedientos →</a></p>
	</div>
{:else}
	<div class="centro">
		<span class="emoji">🌳</span>
		<h1>Hola{nombre ? `, ${nombre}` : ''}</h1>
		<p>Ya estás dentro. Todo lo que riegues de ahora en más queda a tu nombre.</p>
		<p><a href={resolve('/')}>Ver los árboles sedientos →</a></p>
	</div>
{/if}

<style>
	.centro {
		text-align: center;
		margin-top: 3rem;
	}
	.emoji {
		font-size: 4rem;
		display: block;
	}
	.rescatado {
		font-size: 1.1rem;
		margin: 0.5rem 0 0;
	}
	.puntos {
		font-size: 2.5rem;
		font-weight: 800;
		color: var(--verde);
		margin: 0.25rem 0 1rem;
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
	.chico {
		font-size: 0.85rem;
		color: var(--tinta-suave);
	}
</style>
