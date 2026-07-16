<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { supabase } from '$lib/supabase';
	import { dispositivoId } from '$lib/features/riego/dispositivo';
	import { sesion } from '$lib/features/auth/sesion.svelte';

	type Estado = 'form' | 'enviando' | 'mail_enviado';
	let estado: Estado = $state('form');
	let email = $state('');
	let error: string | null = $state(null);
	let porReclamar = $state({ riegos: 0, puntos: 0 });

	onMount(async () => {
		if (sesion.session) {
			goto(resolve('/'));
			return;
		}
		// Lo que este teléfono tiene guardado sin dueño: es el argumento para
		// crear la cuenta, así que se lo mostramos.
		const { data } = await supabase
			.from('riegos')
			.select('puntos')
			.eq('dispositivo_id', dispositivoId())
			.is('perfil_id', null);
		if (data?.length) {
			porReclamar = {
				riegos: data.length,
				puntos: data.reduce((t, r) => t + (r.puntos ?? 0), 0)
			};
		}
	});

	function volverUrl(): string {
		return `${location.origin}${resolve('/auth/callback')}`;
	}

	async function conGoogle() {
		error = null;
		const { error: e } = await supabase.auth.signInWithOAuth({
			provider: 'google',
			options: { redirectTo: volverUrl() }
		});
		if (e) error = 'No pudimos abrir el acceso con Google. Probá con el mail.';
	}

	async function conMail(evento: SubmitEvent) {
		evento.preventDefault();
		error = null;
		estado = 'enviando';
		const { error: e } = await supabase.auth.signInWithOtp({
			email,
			options: { emailRedirectTo: volverUrl() }
		});
		if (e) {
			error = 'No pudimos enviar el mail. ¿Está bien escrito?';
			estado = 'form';
		} else {
			estado = 'mail_enviado';
		}
	}
</script>

<svelte:head>
	<title>Entrar · Árboles Gigantes</title>
</svelte:head>

<p class="volver"><a href={resolve('/')}>← volver</a></p>

{#if estado === 'mail_enviado'}
	<div class="centro">
		<span class="emoji">📬</span>
		<h1>Te mandamos un mail</h1>
		<p>
			Abrí el link que le llegó a <strong>{email}</strong> desde este mismo teléfono y listo, sin contraseñas.
		</p>
		<p class="chico">¿No llegó? Fijate en el spam, o esperá un minuto y probá de nuevo.</p>
	</div>
{:else}
	<div class="centro">
		<span class="emoji">🌳</span>
		{#if porReclamar.riegos > 0}
			<h1>Guardá tus puntos</h1>
			<p>
				Tenés <strong>{porReclamar.riegos}</strong>
				{porReclamar.riegos === 1 ? 'riego' : 'riegos'} y
				<strong>{porReclamar.puntos} puntos</strong> guardados solo en este teléfono. Creá tu cuenta y
				son tuyos para siempre: si cambiás de teléfono, se van con vos.
			</p>
		{:else}
			<h1>Entrá</h1>
			<p>Para que tus riegos, tus puntos y tus insignias queden a tu nombre.</p>
		{/if}
	</div>

	<button class="primario google" onclick={conGoogle} disabled={estado === 'enviando'}>
		Entrar con Google
	</button>

	<p class="separador">o si preferís, con tu mail</p>

	<form onsubmit={conMail}>
		<input
			type="email"
			bind:value={email}
			placeholder="tu@mail.com"
			required
			autocomplete="email"
			disabled={estado === 'enviando'}
		/>
		<button class="secundario" type="submit" disabled={estado === 'enviando'}>
			{estado === 'enviando' ? 'Enviando…' : 'Mandame un link'}
		</button>
	</form>
	<p class="chico">Te llega un link al mail, lo tocás y entrás. No hay contraseña que recordar.</p>

	{#if error}
		<p class="error">{error}</p>
	{/if}
{/if}

<style>
	.volver {
		margin: 0 0 1rem;
	}
	.centro {
		text-align: center;
		margin: 2rem 0;
	}
	.emoji {
		font-size: 3.5rem;
		display: block;
	}
	.centro h1 {
		margin: 0.5rem 0;
	}
	.google {
		margin-top: 1rem;
	}
	.separador {
		text-align: center;
		color: var(--tinta-suave);
		font-size: 0.9rem;
		margin: 1.5rem 0 0.75rem;
	}
	form {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
	}
	input {
		padding: 0.9rem;
		border: 1px solid #d8d3c7;
		border-radius: 12px;
		font-size: 1.05rem;
		font-family: inherit;
		background: white;
		color: var(--tinta);
	}
	button.secundario {
		padding: 0.9rem;
		border: 1px solid var(--verde);
		border-radius: 12px;
		background: transparent;
		color: var(--verde-oscuro);
		font-size: 1.05rem;
		font-weight: 600;
		font-family: inherit;
		cursor: pointer;
	}
	.chico {
		font-size: 0.85rem;
		color: var(--tinta-suave);
		text-align: center;
	}
	.error {
		color: var(--alerta);
		text-align: center;
	}
</style>
