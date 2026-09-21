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
		const { data } = await supabase.rpc('riegos_por_reclamar', {
			p_dispositivo_id: dispositivoId()
		});
		const r = data as { riegos: number; puntos: number } | null;
		if (r && r.riegos > 0) porReclamar = { riegos: r.riegos, puntos: r.puntos };
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

	// Solo local (import.meta.env.DEV): entra como el admin dev que crea
	// supabase/seed.sql, sin magic link ni Google. Evita el loop de PKCE en local.
	// Ver docs/login-local-dev.md.
	async function conDev() {
		error = null;
		estado = 'enviando';
		const { error: e } = await supabase.auth.signInWithPassword({
			// El email TIENE que ser el de admin: es_admin() decide por email, no por
			// perfiles.es_admin. Con otro email entrás pero no podés escribir nada.
			email: 'josepedrodiaz@gmail.com',
			password: 'dev'
		});
		if (e) {
			error = 'No existe el usuario dev. Corré `supabase db reset` para seedearlo.';
			estado = 'form';
		} else {
			goto(resolve('/'));
		}
	}
</script>

<svelte:head>
	<title>Entrar · Árboles Gigantes</title>
</svelte:head>

<p class="volver"><a href={resolve('/')}><span class="fl">◀</span> volver</a></p>

{#if estado === 'mail_enviado'}
	<div class="centro panel">
		<span class="emoji">📬</span>
		<h1>Te mandamos un mail</h1>
		<p>
			Abrí el link que le llegó a <strong>{email}</strong> desde este mismo teléfono y listo, sin contraseñas.
		</p>
		<p class="chico">¿No llegó? Fijate en el spam, o esperá un minuto y probá de nuevo.</p>
	</div>
{:else}
	<div class="centro panel">
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

	{#if import.meta.env.DEV}
		<button class="btn wide dev" onclick={conDev} disabled={estado === 'enviando'}>
			🛠 Entrar como dev (local)
		</button>
	{/if}

	<button class="btn wide" onclick={conGoogle} disabled={estado === 'enviando'}>
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
		<button class="btn ghost wide" type="submit" disabled={estado === 'enviando'}>
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
		font-family: var(--pixel);
		font-size: 9px;
		margin: 12px 0 4px;
	}
	.volver a {
		text-decoration: none;
	}
	.centro {
		text-align: center;
		margin: 10px 0 14px;
		padding: 18px 14px;
	}
	.emoji {
		font-size: 3rem;
		display: block;
	}
	.centro h1 {
		margin: 8px 0;
		color: #fff;
		text-shadow: 3px 3px 0 #000;
	}
	.centro p {
		margin: 8px 0 0;
	}
	.separador {
		text-align: center;
		margin: 16px 0 8px;
	}
	form {
		display: flex;
		flex-direction: column;
		gap: 8px;
	}
	input {
		padding: 12px;
		border: 3px solid var(--edge-d);
		background: var(--panel2);
		color: var(--ink);
		font: inherit;
		box-shadow: inset 3px 3px 0 #1a1528;
	}
	input::placeholder {
		color: #6f6690;
	}
	.chico {
		text-align: center;
		font-size: 16px;
		margin: 10px 4px 0;
	}
	.error {
		color: var(--sed);
		text-align: center;
	}
</style>
