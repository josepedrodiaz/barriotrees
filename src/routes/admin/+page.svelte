<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { gps, seguirPosicion } from '$lib/geo.svelte';
	import { supabase } from '$lib/supabase';
	import { guardarArbol, type ArbolAdmin } from '$lib/features/admin/arboles';

	let { data } = $props();

	let editando: Partial<ArbolAdmin> | null = $state(null);
	let guardando = $state(false);
	let error: string | null = $state(null);

	// El token del clima para el secreto CLIMA_TOKEN de GitHub Actions (BT-33).
	// Se pide a demanda: no anda dando vueltas en la página.
	let climaToken: string | null = $state(null);
	async function verClimaToken() {
		const { data: res } = await supabase.rpc('obtener_clima_token');
		const r = res as { ok?: boolean; token?: string } | null;
		climaToken = r?.ok ? (r.token ?? '(vacío)') : 'No se pudo (¿sos admin?)';
	}

	const especieDe = (id: string) => data.especies.find((e) => e.id === id)?.nombre_comun ?? '—';

	// --- Entregadores de pin (BT-39): la comisión que valida canjes en el evento.
	// Se elige de la lista de registrados por nombre (el mail no sirve: nadie
	// recuerda con qué se registró). ---
	let busca = $state('');
	let tocando: string | null = $state(null);

	const usuariosFiltrados = $derived(
		data.usuarios.filter((u) => u.nombre.toLowerCase().includes(busca.trim().toLowerCase()))
	);

	// --- Sandbox de pruebas (BT-40) ---
	let trabajandoPruebas = $state(false);
	let avisoPruebas: string | null = $state(null);

	async function poblarPruebas() {
		trabajandoPruebas = true;
		avisoPruebas = null;
		const { data: res } = await supabase.rpc('poblar_pruebas', { p_cantidad: 10 });
		const r = res as { ok?: boolean; creados?: number; total?: number } | null;
		trabajandoPruebas = false;
		avisoPruebas = r?.ok
			? `Listo: ${r.creados} árboles nuevos (${r.total} en total).`
			: 'No se pudo poblar.';
		await invalidateAll();
	}

	async function limpiarPruebas() {
		if (
			!confirm(
				'Borra los árboles test-*, sus riegos, y devuelve puntos e insignias a como estaban.\n\nLos pines YA ENTREGADOS no se tocan. ¿Seguimos?'
			)
		)
			return;
		trabajandoPruebas = true;
		avisoPruebas = null;
		const { data: res } = await supabase.rpc('limpiar_pruebas');
		const r = res as {
			ok?: boolean;
			riegos_borrados?: number;
			arboles_borrados?: number;
			perfiles_ajustados?: number;
		} | null;
		trabajandoPruebas = false;
		avisoPruebas = r?.ok
			? `Limpio: ${r.arboles_borrados} árboles y ${r.riegos_borrados} riegos borrados. ${r.perfiles_ajustados} perfil(es) con puntos e insignias corregidos.`
			: 'No se pudo limpiar.';
		await invalidateAll();
	}

	// La opción nuclear: borra TODO el estado de juego, incluidos los pines ya
	// entregados. Confirmación tipeada porque no tiene vuelta atrás.
	async function resetearJuego() {
		if (
			prompt(
				'Esto borra TODOS los riegos, TODAS las insignias (incluso las entregadas) y pone los puntos en cero. Deja solo los árboles reales.\n\nEscribí RESETEAR para confirmar:'
			) !== 'RESETEAR'
		)
			return;
		trabajandoPruebas = true;
		avisoPruebas = null;
		const { data: res } = await supabase.rpc('resetear_juego');
		const r = res as { ok?: boolean; riegos_borrados?: number; insignias_borradas?: number } | null;
		trabajandoPruebas = false;
		avisoPruebas = r?.ok
			? `Reseteo total: ${r.riegos_borrados} riegos y ${r.insignias_borradas} insignias borradas, puntos en cero.`
			: 'No se pudo resetear.';
		await invalidateAll();
	}

	async function setEntregador(id: string, valor: boolean) {
		tocando = id;
		await supabase.rpc('poner_entregador', { p_perfil: id, p_valor: valor });
		await invalidateAll();
		tocando = null;
	}

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

		<label>
			Frecuencia propia (días)
			<input
				type="number"
				step="any"
				min="0"
				bind:value={editando.frecuencia_dias_override}
				placeholder="vacío = la de la especie"
			/>
			<small>
				Cada cuántos días necesita agua ESTE árbol, si difiere de su especie. Vacío usa la de la
				especie. Un valor chico (0.4) lo pone sediento enseguida: sirve para los árboles de prueba.
			</small>
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

<div class="entregadores panel">
	<h2>🧪 Sandbox de pruebas</h2>
	<p class="intro">
		Árboles de mentira (código <code>test-NN</code>) para ensayar el circuito sin ir a la plaza: no
		exigen proximidad y piden agua aunque acabe de llover. Cada árbol se puede regar una vez cada
		12&nbsp;h, por eso conviene tener varios.
	</p>
	<div class="acciones-pruebas">
		<button class="btn sm" disabled={trabajandoPruebas} onclick={poblarPruebas}>
			🌱 Crear 10 árboles de prueba
		</button>
		<button class="btn ghost sm" disabled={trabajandoPruebas} onclick={limpiarPruebas}>
			🧹 Borrar todo lo de prueba
		</button>
	</div>
	{#if avisoPruebas}<p class="aviso-pruebas">{avisoPruebas}</p>{/if}
	<p class="intro">
		Borrar limpia los árboles de prueba, sus riegos, y devuelve puntos e insignias a como estaban.
		Los pines <b>ya entregados</b> no se tocan: ese pin está en la mano de alguien.
	</p>

	<div class="zona-peligro">
		<p class="intro">
			<b>Reseteo total.</b> Borra TODO el estado del juego —todos los riegos, todas las insignias (incluso
			las entregadas) y los puntos a cero—, dejando solo los árboles reales de la plaza. Es para dejar
			la base limpia antes del lanzamiento. No tiene vuelta atrás.
		</p>
		<button class="btn danger sm" disabled={trabajandoPruebas} onclick={resetearJuego}>
			💣 Resetear todo el juego
		</button>
	</div>
</div>

<div class="entregadores panel">
	<h2>🎖 Entregadores de pin</h2>
	<p class="intro">
		Quienes pueden validar y entregar pines en el evento. Solo entran al validador de canje, nada
		más. Elegí a la persona de la lista (tiene que haber entrado a la app una vez).
	</p>

	<input class="busca" type="search" bind:value={busca} placeholder="Buscar por nombre…" />

	<ul class="lista">
		{#each usuariosFiltrados as u (u.id)}
			<li>
				<span>
					<strong>{u.nombre}</strong>
					{#if u.entregador}<span class="tag-ok">✓ entregador</span>{/if}
				</span>
				{#if u.entregador}
					<button
						class="enlace"
						disabled={tocando === u.id}
						onclick={() => setEntregador(u.id, false)}>quitar</button
					>
				{:else}
					<button
						class="btn sm"
						disabled={tocando === u.id}
						onclick={() => setEntregador(u.id, true)}>hacer entregador</button
					>
				{/if}
			</li>
		{:else}
			<li class="suave">Nadie registrado coincide con la búsqueda.</li>
		{/each}
	</ul>
</div>

<div class="ayuda-canje panel">
	<h2>🎖 Para entregar un pin</h2>
	<p>
		Escaneá con la cámara del teléfono el QR que te muestra el vecino en su pantalla. Se abre la
		validación: si el pin corresponde, tocás <b>Entregué el pin</b> y queda marcado. Si ese QR ya se usó,
		te avisa — no se puede cobrar dos veces.
	</p>
</div>

<div class="ayuda-canje panel">
	<h2>🌦️ Clima (tarea diaria)</h2>
	<p>
		El estado de los árboles ya usa el clima real de la plaza (lluvia y evaporación). La tarea que
		lo actualiza corre sola en GitHub una vez por día. Para que funcione hay que cargar el token una
		sola vez como secreto <b>CLIMA_TOKEN</b> en GitHub (Settings → Secrets → Actions).
	</p>
	{#if climaToken}
		<p class="token">{climaToken}</p>
	{:else}
		<button class="btn sm" onclick={verClimaToken}>Ver el token del clima</button>
	{/if}
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
	.entregadores {
		margin-top: 24px;
		padding: 14px;
	}
	.entregadores h2 {
		color: var(--gold);
	}
	.entregadores .intro {
		font-size: 0.85rem;
		color: var(--dim);
		margin: 0 0 1rem;
	}
	.busca {
		width: 100%;
		margin: 0;
	}
	.acciones-pruebas {
		display: flex;
		flex-wrap: wrap;
		gap: 0.6rem;
		margin-bottom: 0.8rem;
	}
	.aviso-pruebas {
		margin: 0 0 0.8rem;
		font-size: 0.9rem;
		color: var(--feliz);
	}
	.zona-peligro {
		margin-top: 1rem;
		padding-top: 0.8rem;
		border-top: 2px solid var(--sed);
	}
	.zona-peligro .intro {
		margin-bottom: 0.6rem;
	}
	code {
		font-family: var(--read);
		color: var(--gold);
	}
	.tag-ok {
		margin-left: 0.5rem;
		font-size: 0.72rem;
		color: var(--feliz);
	}
	.lista {
		list-style: none;
		padding: 0;
		margin: 1rem 0 0;
	}
	.lista li {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		padding: 0.5rem 0;
		border-top: 2px solid var(--edge-l);
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
	.token {
		font-family: var(--read);
		font-size: 18px;
		color: var(--gold);
		background: var(--panel2);
		border: 2px solid var(--edge-d);
		padding: 8px 10px;
		margin: 8px 0 0;
		word-break: break-all;
		user-select: all;
	}
	.pie {
		margin-top: 1rem;
		font-size: 0.85rem;
		color: var(--dim);
	}
</style>
