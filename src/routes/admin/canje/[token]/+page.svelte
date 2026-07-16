<script lang="ts">
	// El validador: acá cae el de la comisión cuando escanea el QR del vecino
	// con la cámara del teléfono. Ve de quién es y qué es, y recién entonces
	// confirma. Es la mecánica de entrega del evento (decisión 18).
	import { page } from '$app/state';
	import { resolve } from '$app/paths';
	import { supabase } from '$lib/supabase';
	import { sesion } from '$lib/features/auth/sesion.svelte';
	import Pin from '$lib/ui/Pin.svelte';

	interface Canje {
		ok: boolean;
		motivo?: string;
		estado?: string;
		insignia?: string;
		vecino?: string;
		canjeada_en?: string;
		entregado_por?: string;
	}

	let canje: Canje | null = $state(null);
	let entregando = $state(false);
	let cargadoPara: string | null = $state(null);

	const token = $derived(page.params.token!);

	$effect(() => {
		const id = sesion.session?.user.id;
		if (sesion.cargando || !id || !sesion.perfil?.es_admin || cargadoPara === token) return;
		cargadoPara = token;
		ver();
	});

	async function ver() {
		const { data } = await supabase.rpc('ver_canje', { p_token: token });
		canje = data as unknown as Canje;
	}

	async function entregar() {
		entregando = true;
		const { data } = await supabase.rpc('canjear_pin', { p_token: token });
		canje = data as unknown as Canje;
		entregando = false;
	}

	function fecha(iso?: string): string {
		if (!iso) return '';
		return new Date(iso).toLocaleString('es-AR', {
			day: '2-digit',
			month: '2-digit',
			hour: '2-digit',
			minute: '2-digit'
		});
	}
</script>

<svelte:head>
	<title>Canje · Panel</title>
</svelte:head>

{#if !canje}
	<p class="esperando">Leyendo el QR…</p>
{:else if !canje.ok && canje.motivo === 'inexistente'}
	<div class="resultado panel fail">
		<div class="mh">🔒 ESTE QR NO SIRVE</div>
		<p>No corresponde a ninguna insignia. ¿Es un QR de esta app?</p>
	</div>
{:else if canje.estado === 'entregado'}
	<!-- El caso que justifica todo esto: el pin ya salió. Sin listas de papel y
	     sin discusión. -->
	<div class="resultado panel fail">
		<div class="mh">✋ YA SE ENTREGÓ</div>
		<p class="quien">{canje.insignia} de <b>{canje.vecino}</b></p>
		<p class="cuando">
			Entregado el {fecha(canje.canjeada_en)}{#if canje.entregado_por}
				por {canje.entregado_por}{/if}
		</p>
		<p class="aviso">No corresponde entregar otro pin por esta insignia.</p>
	</div>
{:else}
	<div class="resultado panel">
		<div class="pin"><Pin px={90} /></div>
		<div class="mh">🎖 PIN A ENTREGAR</div>
		<p class="insignia">{canje.insignia}</p>
		<p class="quien">para <b>{canje.vecino}</b></p>
		<button class="btn gold wide" onclick={entregar} disabled={entregando}>
			{entregando ? 'MARCANDO…' : 'ENTREGUÉ EL PIN ✓'}
		</button>
		<p class="aviso">Tocá recién cuando el pin ya está en su mano.</p>
	</div>
{/if}

<p class="volver"><a href={resolve('/admin')}>◀ volver al panel</a></p>

<style>
	.esperando {
		text-align: center;
		color: var(--dim);
	}
	.resultado {
		padding: 20px 16px;
		text-align: center;
		margin: 10px 0;
		border-color: var(--feliz);
	}
	.resultado.fail {
		border-color: var(--sed);
	}
	.pin {
		margin-bottom: 10px;
	}
	.mh {
		font-family: var(--pixel);
		font-size: 10px;
		line-height: 1.5;
		color: var(--feliz);
		text-shadow: 2px 2px 0 #14401f;
		margin-bottom: 12px;
	}
	.fail .mh {
		color: var(--sed);
		text-shadow: 2px 2px 0 #400f10;
	}
	.insignia {
		font-family: var(--pixel);
		font-size: 13px;
		line-height: 1.5;
		color: var(--gold);
		text-shadow: 2px 2px 0 #6b4d00;
		margin: 0 0 6px;
	}
	.quien {
		font-size: 19px;
		color: var(--ink);
		margin: 0 0 16px;
	}
	.cuando {
		color: var(--dim);
		margin: 0 0 10px;
	}
	.aviso {
		font-size: 16px;
		color: var(--dim);
		margin: 12px auto 0;
		max-width: 32ch;
	}
	.volver {
		text-align: center;
		margin-top: 20px;
	}
</style>
