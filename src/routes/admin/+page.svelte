<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { gps, seguirPosicion } from '$lib/geo.svelte';
	import { guardarArbol, type ArbolAdmin } from '$lib/features/admin/arboles';

	let { data } = $props();

	let editando: Partial<ArbolAdmin> | null = $state(null);
	let guardando = $state(false);
	let error: string | null = $state(null);

	const especieDe = (id: string) => data.especies.find((e) => e.id === id)?.nombre_comun ?? '—';

	function nuevo() {
		error = null;
		editando = {
			codigo: '',
			especie_id: data.especies[0]?.id ?? '',
			sector: '',
			activo: true
		};
	}

	function editar(a: (typeof data.arboles)[number]) {
		error = null;
		editando = { ...a };
	}

	function tomarUbicacion() {
		seguirPosicion();
		if (gps.fix && editando) {
			editando.lat = Number(gps.fix.lat.toFixed(7));
			editando.lng = Number(gps.fix.lng.toFixed(7));
		}
	}

	async function guardar(evento: SubmitEvent) {
		evento.preventDefault();
		if (!editando) return;
		guardando = true;
		error = null;
		const res = await guardarArbol(editando);
		guardando = false;
		if (res.ok) {
			editando = null;
			await invalidateAll();
		} else {
			error = res.error;
		}
	}
</script>

<svelte:head>
	<title>Árboles · Panel</title>
</svelte:head>

<div class="titulo">
	<h1>Árboles</h1>
	{#if !editando}
		<button class="btn sm" onclick={nuevo}>+ Nuevo</button>
	{/if}
</div>

{#if editando}
	<form class="panel" onsubmit={guardar}>
		<h2>{editando.id ? `Editar ${editando.codigo}` : 'Nuevo árbol'}</h2>

		<label>
			Código
			<input bind:value={editando.codigo} placeholder="jaca-11" required />
			<small>Es lo que va en la URL del QR. Corto y sin espacios.</small>
		</label>

		<label>
			Especie
			<select bind:value={editando.especie_id} required>
				{#each data.especies as e (e.id)}
					<option value={e.id}>{e.nombre_comun} (cada {e.frecuencia_dias} días)</option>
				{/each}
			</select>
		</label>

		<label>
			Sector
			<input bind:value={editando.sector} placeholder="Galería central" />
		</label>

		<label>
			Fecha de plantación
			<input type="date" bind:value={editando.fecha_plantacion} />
		</label>

		<div class="coords">
			<label>
				Latitud
				<input type="number" step="any" bind:value={editando.lat} placeholder="-34.9787" />
			</label>
			<label>
				Longitud
				<input type="number" step="any" bind:value={editando.lng} placeholder="-58.0204" />
			</label>
		</div>
		<button type="button" class="btn sm" onclick={tomarUbicacion}>
			📍 {gps.fix ? 'Usar donde estoy parado' : 'Pedir mi ubicación'}
		</button>
		<small class="ayuda">
			Sin coordenadas, el árbol no exige estar cerca para regarlo. Lo mejor es cargarlas parado al
			lado del árbol.
		</small>

		<label class="fila">
			<input type="checkbox" bind:checked={editando.activo} />
			Activo (se ve en la app)
		</label>

		{#if error}<p class="error">{error}</p>{/if}

		<div class="acciones">
			<button class="btn" type="submit" disabled={guardando}>
				{guardando ? 'Guardando…' : 'Guardar'}
			</button>
			<button type="button" class="btn ghost sm" onclick={() => (editando = null)}>Cancelar</button>
		</div>
	</form>
{/if}

<table class="panel">
	<thead>
		<tr><th>Código</th><th>Especie</th><th>Sector</th><th>GPS</th><th></th></tr>
	</thead>
	<tbody>
		{#each data.arboles as a (a.id)}
			<tr class:inactivo={!a.activo}>
				<td
					><strong>{a.codigo}</strong>{#if !a.activo}<span class="tag">inactivo</span>{/if}</td
				>
				<td>{especieDe(a.especie_id)}</td>
				<td class="suave">{a.sector ?? '—'}</td>
				<td class="suave">{a.lat != null ? '✓' : '—'}</td>
				<td><button class="enlace" onclick={() => editar(a)}>editar</button></td>
			</tr>
		{:else}
			<tr><td colspan="5">Todavía no hay árboles.</td></tr>
		{/each}
	</tbody>
</table>

<p class="pie">
	{data.arboles.length} árboles · {data.arboles.filter((a) => a.activo).length} activos
</p>

<div class="ayuda-canje panel">
	<h2>🎖 Para entregar un pin</h2>
	<p>
		Escaneá con la cámara del teléfono el QR que te muestra el vecino en su pantalla. Se abre la
		validación: si el pin corresponde, tocás <b>Entregué el pin</b> y queda marcado. Si ese QR ya se usó,
		te avisa — no se puede cobrar dos veces.
	</p>
</div>

<style>
	.titulo {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
	}
	h1 {
		margin: 0;
	}
	h2 {
		margin: 0 0 1rem;
		font-size: 1.05rem;
	}
	form {
		margin: 1.5rem 0 2rem;
		padding: 1.25rem;
		padding: 14px;
	}
	label {
		display: block;
		margin-bottom: 0.9rem;
		font-size: 0.85rem;
		color: var(--dim);
	}
	label.fila {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		color: var(--ink);
	}
	input,
	select {
		display: block;
		width: 100%;
		margin-top: 0.25rem;
		padding: 0.6rem;
		border: 3px solid var(--edge-d);
		font: inherit;
		background: var(--panel2);
		color: var(--ink);
	}
	label.fila input {
		width: auto;
		margin: 0;
	}
	small {
		display: block;
		margin-top: 0.25rem;
		font-size: 0.78rem;
		color: var(--dim);
	}
	.ayuda {
		margin: 0.5rem 0 1rem;
	}
	.coords {
		display: flex;
		gap: 0.75rem;
	}
	.coords label {
		flex: 1;
		margin-bottom: 0.5rem;
	}
	.acciones {
		display: flex;
		align-items: center;
		gap: 1rem;
		margin-top: 1rem;
	}

	button.enlace {
		background: none;
		border: none;
		padding: 0;
		font: inherit;
		font-size: 0.85rem;
		color: var(--violet-l);
		text-decoration: underline;
		cursor: pointer;
	}
	table {
		width: 100%;
		border-collapse: collapse;
		font-size: 0.9rem;
	}
	th {
		text-align: left;
		font-size: 0.75rem;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		color: var(--dim);
		font-weight: 600;
		padding: 0 0 0.5rem;
	}
	td {
		padding: 0.6rem 0.5rem 0.6rem 0;
		border-top: 2px solid var(--edge-l);
	}
	tr.inactivo {
		opacity: 0.5;
	}
	.tag {
		margin-left: 0.4rem;
		font-size: 0.7rem;
		color: var(--dim);
	}
	.suave {
		color: var(--dim);
	}
	.error {
		color: var(--sed);
		font-size: 0.9rem;
	}
	.ayuda-canje {
		margin-top: 24px;
		padding: 14px;
	}
	.ayuda-canje h2 {
		margin: 0 0 8px;
		color: var(--gold);
	}
	.ayuda-canje p {
		margin: 0;
		font-size: 17px;
		color: var(--dim);
	}
	.ayuda-canje b {
		color: var(--ink);
	}
	.pie {
		margin-top: 1rem;
		font-size: 0.85rem;
		color: var(--dim);
	}
</style>
