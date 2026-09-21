<script lang="ts">
	import { resolve } from '$app/paths';
	import { sesion } from '$lib/features/auth/sesion.svelte';
	import { reportarPeligro, TIPOS_REPORTE, type TipoReporte } from './reportarPeligro';

	let { arbolId }: { arbolId: string } = $props();

	type Fase = 'cerrado' | 'form' | 'enviando' | 'listo' | 'error';
	let fase: Fase = $state('cerrado');
	let tipo: TipoReporte | null = $state(null);
	let descripcion = $state('');

	const logueado = $derived(!!sesion.perfil);

	async function enviar() {
		if (!tipo) return;
		fase = 'enviando';
		const res = await reportarPeligro(arbolId, tipo, descripcion);
		if (res.ok) fase = 'listo';
		else fase = 'error';
	}

	function reset() {
		tipo = null;
		descripcion = '';
		fase = 'cerrado';
	}
</script>

<div class="reporte">
	{#if fase === 'cerrado'}
		<button class="btn ghost wide" onclick={() => (fase = 'form')}>🚨 REPORTAR UN PROBLEMA</button>
	{:else if fase === 'listo'}
		<div class="panel aviso ok">
			<div class="cab">✅ ¡GRACIAS POR AVISAR!</div>
			<p>La comisión lo revisa. Si se confirma, te sumamos puntos.</p>
		</div>
	{:else if !logueado}
		<div class="panel aviso lock">
			<div class="cab">🔒 NECESITÁS UNA CUENTA</div>
			<p>Para reportar y que te sumemos los puntos por avisar.</p>
		</div>
		<a class="btn wide" href={resolve('/entrar')}>CREAR CUENTA O ENTRAR ▶</a>
		<button class="btn ghost sm" onclick={reset}>Cancelar</button>
	{:else}
		<div class="panel form">
			<p class="titulo">¿Qué le pasa al árbol?</p>
			<div class="tipos">
				{#each TIPOS_REPORTE as t (t.valor)}
					<button
						class="tipo"
						class:sel={tipo === t.valor}
						onclick={() => (tipo = t.valor)}
						type="button"
					>
						<span class="em">{t.emoji}</span>{t.etiqueta}
					</button>
				{/each}
			</div>
			<textarea
				bind:value={descripcion}
				placeholder="Contanos un poco más (opcional)"
				rows="2"
				maxlength="280"></textarea>
			{#if fase === 'error'}
				<p class="err">No se pudo enviar. ¿Anda la conexión? Probá de nuevo.</p>
			{/if}
			<button class="btn green wide" disabled={!tipo || fase === 'enviando'} onclick={enviar}>
				{fase === 'enviando' ? 'ENVIANDO…' : 'ENVIAR REPORTE'}
			</button>
			<button class="btn ghost sm" onclick={reset} disabled={fase === 'enviando'}>Cancelar</button>
		</div>
	{/if}
</div>

<style>
	.reporte {
		margin: 10px 0 0;
	}
	.aviso {
		padding: 14px;
		text-align: center;
	}
	.aviso .cab {
		font-family: var(--pixel);
		font-size: 9px;
		line-height: 1.5;
		margin-bottom: 8px;
	}
	.aviso p {
		font-size: 16px;
		color: var(--ink);
		margin: 0;
	}
	.aviso.ok {
		border-color: var(--feliz);
	}
	.aviso.ok .cab {
		color: var(--feliz);
	}
	.aviso.lock {
		border-color: var(--sed);
	}
	.aviso.lock .cab {
		color: var(--sed);
	}
	.form {
		padding: 14px;
	}
	.form .titulo {
		font-family: var(--pixel);
		font-size: 9px;
		color: var(--violet-l);
		margin: 0 0 12px;
	}
	.tipos {
		display: flex;
		flex-direction: column;
		gap: 8px;
		margin-bottom: 12px;
	}
	.tipo {
		display: flex;
		align-items: center;
		gap: 12px;
		width: 100%;
		text-align: left;
		font-size: 16px;
		color: var(--ink);
		background: rgba(255, 255, 255, 0.04);
		border: 2px solid #2a2440;
		padding: 11px 12px;
		cursor: pointer;
	}
	.tipo .em {
		font-size: 22px;
		width: 26px;
		text-align: center;
		flex: none;
	}
	.tipo.sel {
		border-color: var(--feliz);
		background: rgba(70, 195, 106, 0.14);
	}
	textarea {
		width: 100%;
		box-sizing: border-box;
		font: inherit;
		font-size: 16px;
		color: var(--ink);
		background: rgba(255, 255, 255, 0.04);
		border: 2px solid #2a2440;
		padding: 10px;
		resize: vertical;
		margin-bottom: 10px;
	}
	.err {
		color: var(--sed);
		font-size: 15px;
		margin: 0 0 8px;
	}
	.btn.sm {
		display: block;
		margin: 8px auto 0;
	}
</style>
