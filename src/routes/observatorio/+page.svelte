<script lang="ts">
	import { resolve } from '$app/paths';

	let { data } = $props();

	// --- selección de árbol para la curva ---
	const vivos = $derived(data.arboles.filter((a) => !a.muerto));
	let codigoSel = $state<string | null>(null);
	const sel = $derived(
		data.arboles.find((a) => a.codigo === codigoSel) ?? vivos[0] ?? data.arboles[0] ?? null
	);

	// --- geometría de la curva de déficit ---
	const W = 760;
	const H = 300;
	const PL = 46;
	const PR = 18;
	const PT = 16;
	const PB = 34;
	const innerW = W - PL - PR;
	const innerH = H - PT - PB;

	const chart = $derived.by(() => {
		if (!sel || !sel.serie.length) return null;
		const s = sel.serie;
		const n = s.length;
		const maxDef = Math.max(...s.map((p) => p.deficit));
		const maxLluvia = Math.max(...s.map((p) => p.lluvia), 0);
		const yMax = Math.max(maxDef, sel.umbralCritico * 1.15, maxLluvia, 10);
		const x = (i: number) => PL + (n === 1 ? innerW / 2 : (i / (n - 1)) * innerW);
		const y = (v: number) => PT + innerH - (v / yMax) * innerH;
		const linea = s
			.map((p, i) => `${i === 0 ? 'M' : 'L'}${x(i).toFixed(1)} ${y(p.deficit).toFixed(1)}`)
			.join(' ');
		const barW = Math.max(1.5, (innerW / n) * 0.5);
		return {
			s,
			n,
			x,
			y,
			yMax,
			linea,
			barW,
			ySed: y(sel.umbralSediento),
			yCrit: y(sel.umbralCritico),
			y0: y(0),
			ticksY: [0, Math.round(sel.umbralSediento), Math.round(sel.umbralCritico), Math.round(yMax)]
		};
	});

	// --- hover ---
	let hover = $state<number | null>(null);
	function moverHover(e: MouseEvent) {
		if (!chart) return;
		const svg = e.currentTarget as SVGSVGElement;
		const r = svg.getBoundingClientRect();
		const px = ((e.clientX - r.left) / r.width) * W;
		const i = Math.round(((px - PL) / innerW) * (chart.n - 1));
		hover = Math.max(0, Math.min(chart.n - 1, i));
	}

	const ESTADO: Record<string, { txt: string; clase: string }> = {
		feliz: { txt: 'Óptimo', clase: 'e-feliz' },
		bien: { txt: 'Adecuado', clase: 'e-bien' },
		sediento: { txt: 'Déficit', clase: 'e-sed' },
		muy_sediento: { txt: 'Déficit severo', clase: 'e-crit' }
	};

	function fechaCorta(iso: string | null): string {
		if (!iso) return '—';
		const [, m, d] = iso.split('-');
		return `${d}/${m}`;
	}
	const pct = (x: number) => `${Math.round(x * 100)}%`;
</script>

<svelte:head>
	<title>Observatorio del arbolado · Plaza Gigante del Oeste</title>
</svelte:head>

<div class="obs">
	<div class="ancho">
		<header class="cab">
			<p class="institucion">Plaza Gigante del Oeste · La Plata · Comisión de arbolado</p>
			<h1>Observatorio del arbolado joven</h1>
			<p class="sub">
				Monitoreo del balance hídrico del arbolado en establecimiento. Los datos surgen del riego
				comunitario registrado en la app y del clima diario de la plaza (Open-Meteo, ET0
				FAO&#8209;56). Cada riego y cada lluvia quedan fechados; con eso se reconstruye, día por
				día, cuánta agua necesitó y recibió cada árbol.
			</p>
			{#if data.desde}
				<p class="periodo">
					Período analizado: {fechaCorta(data.desde)} — {fechaCorta(data.hasta)} · {data.dias} días ·
					{data.plaza.total} árboles del programa
				</p>
			{/if}
		</header>

		<section class="resumen">
			<div class="stat">
				<span class="n">{pct(data.plaza.supervivencia)}</span>
				<span class="l">Supervivencia</span>
			</div>
			<div class="stat">
				<span class="n">{data.plaza.vivos}<span class="sep">/</span>{data.plaza.total}</span>
				<span class="l">Vivos · {data.plaza.muertos} bajas</span>
			</div>
			<div class="stat">
				<span class="n">{data.plaza.estresPromedio}</span>
				<span class="l">Días de déficit (prom.)</span>
			</div>
			<div class="stat">
				<span class="n">{data.plaza.riegosTotales}</span>
				<span class="l">Riegos registrados</span>
			</div>
			<div class="stat">
				<span class="n">{data.plaza.aguaLitros}<span class="u"> L</span></span>
				<span class="l">Agua aplicada (est.)</span>
			</div>
			<div class="stat">
				<span class="n">{data.plaza.lluviaAcum}<span class="u"> mm</span></span>
				<span class="l">Lluvia acumulada</span>
			</div>
			<div class="stat">
				<span class="n">{data.plaza.et0Acum}<span class="u"> mm</span></span>
				<span class="l">ET0 acumulada</span>
			</div>
		</section>

		<section class="grafico">
			<div class="titulo-g">
				<h2>Balance hídrico por árbol</h2>
				<label>
					Árbol:
					<select bind:value={codigoSel}>
						{#each data.arboles as a (a.codigo)}
							<option value={a.codigo}>{a.codigo}{a.muerto ? ' ✝' : ''} — {a.especie}</option>
						{/each}
					</select>
				</label>
			</div>

			{#if chart && sel}
				<p class="lead">
					Déficit de agua en el suelo (mm), estimado como evapotranspiración menos lluvia y riegos,
					reiniciado en cada riego. Las bandas marcan el umbral de estrés de <em>{sel.especie}</em>
					(F&nbsp;=&nbsp;{sel.f} días).
				</p>
				<div class="svg-wrap">
					<svg
						viewBox="0 0 {W} {H}"
						role="img"
						onmousemove={moverHover}
						onmouseleave={() => (hover = null)}
					>
						<!-- bandas de estado -->
						<rect
							x={PL}
							y={chart.ySed}
							width={innerW}
							height={chart.y0 - chart.ySed}
							class="banda verde"
						/>
						<rect
							x={PL}
							y={chart.yCrit}
							width={innerW}
							height={chart.ySed - chart.yCrit}
							class="banda ambar"
						/>
						<rect x={PL} y={PT} width={innerW} height={chart.yCrit - PT} class="banda roja" />

						<!-- ejes y grilla -->
						{#each chart.ticksY as t (t)}
							<line x1={PL} x2={W - PR} y1={chart.y(t)} y2={chart.y(t)} class="grid" />
							<text x={PL - 8} y={chart.y(t) + 3} class="tick">{t}</text>
						{/each}
						<text
							x={12}
							y={PT + innerH / 2}
							class="eje-y"
							transform="rotate(-90 12 {PT + innerH / 2})">déficit (mm)</text
						>

						<!-- lluvia (mismo eje mm) -->
						{#each chart.s as p, i (p.fecha)}
							{#if p.lluvia > 0}
								<rect
									x={chart.x(i) - chart.barW / 2}
									y={chart.y(p.lluvia)}
									width={chart.barW}
									height={chart.y0 - chart.y(p.lluvia)}
									class="lluvia"
								/>
							{/if}
						{/each}

						<!-- curva de déficit -->
						<path d={chart.linea} class="curva" />

						<!-- riegos -->
						{#each chart.s as p, i (p.fecha)}
							{#if p.huboRiego}
								<circle cx={chart.x(i)} cy={chart.y0} r="3.5" class="riego" />
							{/if}
						{/each}

						<!-- hover -->
						{#if hover !== null && chart.s[hover]}
							<line x1={chart.x(hover)} x2={chart.x(hover)} y1={PT} y2={chart.y0} class="cursor" />
							<circle
								cx={chart.x(hover)}
								cy={chart.y(chart.s[hover].deficit)}
								r="4"
								class="punto"
							/>
						{/if}

						<!-- fechas x (primera, media, última) -->
						{#each [0, Math.floor(chart.n / 2), chart.n - 1] as i (i)}
							<text x={chart.x(i)} y={H - 8} class="tick-x">{fechaCorta(chart.s[i].fecha)}</text>
						{/each}
					</svg>

					{#if hover !== null && chart.s[hover]}
						{@const p = chart.s[hover]}
						<div class="tip" style="left: {(chart.x(hover) / W) * 100}%">
							<strong>{fechaCorta(p.fecha)}</strong>
							<span>Déficit: {p.deficit} mm</span>
							<span>{ESTADO[p.estado]?.txt ?? p.estado}</span>
							{#if p.huboRiego}<span class="ok">Regado</span>{/if}
							{#if p.lluvia > 0}<span class="ll">Lluvia: {p.lluvia} mm</span>{/if}
						</div>
					{/if}
				</div>

				<div class="leyenda">
					<span><i class="sw curva-sw"></i> Déficit</span>
					<span><i class="sw lluvia-sw"></i> Lluvia</span>
					<span><i class="sw riego-sw"></i> Riego</span>
					<span class="banda-ley"><i class="sw sw-verde"></i> Bien</span>
					<span class="banda-ley"><i class="sw sw-ambar"></i> Déficit</span>
					<span class="banda-ley"><i class="sw sw-roja"></i> Severo</span>
				</div>
			{:else}
				<p class="vacio">Todavía no hay datos suficientes para graficar.</p>
			{/if}
		</section>

		<section class="tabla">
			<h2>Detalle por árbol</h2>
			<div class="scroll">
				<table>
					<thead>
						<tr>
							<th>Árbol</th>
							<th>Especie</th>
							<th>Estado actual</th>
							<th class="num">Días déficit</th>
							<th class="num">Severos</th>
							<th class="num">Bien atendido</th>
							<th class="num">Riegos</th>
							<th class="num">Últ. riego</th>
							<th class="num">ETc (mm)</th>
						</tr>
					</thead>
					<tbody>
						{#each data.arboles as a (a.codigo)}
							<tr class:muerto={a.muerto}>
								<td><strong>{a.codigo}</strong></td>
								<td class="esp"
									><em>{a.especieCientifico}</em><br /><span class="comun">{a.especie}</span></td
								>
								<td>
									{#if a.muerto}
										<span class="pill e-muerto">✝ Baja {fechaCorta(a.fechaDefuncion)}</span>
									{:else}
										<span class="pill {ESTADO[a.estado ?? '']?.clase ?? ''}"
											>{ESTADO[a.estado ?? '']?.txt ?? a.estado}</span
										>
									{/if}
								</td>
								<td class="num">{a.diasEstres}</td>
								<td class="num">{a.diasCriticos}</td>
								<td class="num">{pct(a.cobertura)}</td>
								<td class="num">{a.riegos}</td>
								<td class="num">{fechaCorta(a.ultimoRiego)}</td>
								<td class="num">{a.etc}</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</section>

		<section class="nota">
			<h2>Nota metodológica</h2>
			<p>
				El déficit hídrico es un <strong>modelo de balance</strong>, no una medición directa de
				humedad de suelo. Se calcula día a día como ET0&nbsp;×&nbsp;Kc menos los aportes (lluvia y
				riego), con el suelo lleno tras cada riego y saturación a los aportes fuertes. La ET0 es la
				de referencia FAO&#8209;56 (Penman&#8209;Monteith) provista por Open-Meteo para las
				coordenadas de la plaza; el coeficiente de cultivo Kc y la frecuencia objetivo F por especie
				son valores iniciales a refinar con la comisión de arbolado. Es un indicador continuo y
				comparable entre árboles, útil para priorizar el cuidado; para rigor fino haría falta
				capacidad de campo, profundidad radicular y, eventualmente, sensores de humedad.
			</p>
		</section>

		<footer class="pie">
			<a href={resolve('/')}>← Volver a Árboles Gigantes</a>
		</footer>
	</div>
</div>

<style>
	/* Sale del juego: fondo claro, tipografía de informe, a pantalla completa
	   por encima del shell oscuro de la app. */
	.obs {
		position: fixed;
		inset: 0;
		overflow-y: auto;
		background: #f6f5f0;
		color: #22221c;
		font-family:
			'Inter',
			system-ui,
			-apple-system,
			'Segoe UI',
			Roboto,
			sans-serif;
		font-size: 16px;
		line-height: 1.55;
		-webkit-font-smoothing: antialiased;
	}
	.obs :global(svg) {
		image-rendering: auto;
	}
	.ancho {
		max-width: 860px;
		margin: 0 auto;
		padding: 40px 22px 80px;
	}

	h1 {
		font-family: Georgia, 'Times New Roman', serif;
		font-weight: 600;
		font-size: clamp(1.8rem, 5vw, 2.5rem);
		line-height: 1.1;
		letter-spacing: -0.01em;
		margin: 4px 0 12px;
	}
	h2 {
		font-family: Georgia, 'Times New Roman', serif;
		font-weight: 600;
		font-size: 1.3rem;
		margin: 0 0 10px;
	}
	.cab {
		border-bottom: 1px solid #d8d6cc;
		padding-bottom: 22px;
	}
	.institucion {
		font-size: 0.78rem;
		letter-spacing: 0.02em;
		color: #7a786c;
		margin: 0;
	}
	.sub {
		max-width: 62ch;
		color: #454339;
		margin: 0 0 10px;
	}
	.periodo {
		font-size: 0.85rem;
		color: #7a786c;
		margin: 0;
		font-variant-numeric: tabular-nums;
	}

	/* resumen: números grandes, etiqueta chica, separados por aire y una regla
	   fina — sin cajas pesadas. */
	.resumen {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
		gap: 20px 28px;
		margin: 28px 0 40px;
	}
	.stat {
		display: flex;
		flex-direction: column;
		gap: 3px;
		border-left: 2px solid #cfae5a;
		padding-left: 12px;
	}
	.stat .n {
		font-size: 1.7rem;
		font-weight: 600;
		font-variant-numeric: tabular-nums;
		letter-spacing: -0.01em;
	}
	.stat .n .u,
	.stat .n .sep {
		font-size: 1rem;
		font-weight: 400;
		color: #7a786c;
	}
	.stat .l {
		font-size: 0.8rem;
		color: #6a685d;
	}

	.grafico {
		margin: 8px 0 44px;
	}
	.titulo-g {
		display: flex;
		align-items: baseline;
		justify-content: space-between;
		gap: 16px;
		flex-wrap: wrap;
	}
	.titulo-g label {
		font-size: 0.85rem;
		color: #6a685d;
	}
	select {
		font: inherit;
		font-size: 0.85rem;
		padding: 4px 8px;
		border: 1px solid #c9c7bb;
		background: #fff;
		border-radius: 3px;
		color: inherit;
	}
	.lead {
		max-width: 66ch;
		font-size: 0.9rem;
		color: #454339;
		margin: 0 0 14px;
	}
	.svg-wrap {
		position: relative;
	}
	svg {
		width: 100%;
		height: auto;
		display: block;
	}
	.banda.verde {
		fill: rgba(76, 122, 90, 0.1);
	}
	.banda.ambar {
		fill: rgba(196, 142, 46, 0.13);
	}
	.banda.roja {
		fill: rgba(180, 74, 62, 0.12);
	}
	.grid {
		stroke: #e2e0d6;
		stroke-width: 1;
	}
	.tick {
		fill: #8a887c;
		font-size: 11px;
		text-anchor: end;
		font-variant-numeric: tabular-nums;
	}
	.tick-x {
		fill: #8a887c;
		font-size: 11px;
		text-anchor: middle;
	}
	.eje-y {
		fill: #8a887c;
		font-size: 11px;
		text-anchor: middle;
	}
	.lluvia {
		fill: rgba(58, 107, 138, 0.4);
	}
	.curva {
		fill: none;
		stroke: #2a2a22;
		stroke-width: 2;
		stroke-linejoin: round;
		stroke-linecap: round;
	}
	.riego {
		fill: #3f7d54;
	}
	.cursor {
		stroke: #b5493e;
		stroke-width: 1;
		stroke-dasharray: 3 3;
	}
	.punto {
		fill: #b5493e;
	}
	.tip {
		position: absolute;
		top: 6px;
		transform: translateX(-50%);
		background: #22221c;
		color: #f6f5f0;
		border-radius: 4px;
		padding: 6px 9px;
		font-size: 0.78rem;
		display: flex;
		flex-direction: column;
		gap: 1px;
		pointer-events: none;
		white-space: nowrap;
	}
	.tip strong {
		font-variant-numeric: tabular-nums;
	}
	.tip .ok {
		color: #7fc99a;
	}
	.tip .ll {
		color: #86b8d6;
	}
	.leyenda {
		display: flex;
		flex-wrap: wrap;
		gap: 8px 18px;
		font-size: 0.8rem;
		color: #6a685d;
		margin-top: 12px;
	}
	.leyenda span {
		display: inline-flex;
		align-items: center;
		gap: 6px;
	}
	.sw {
		width: 13px;
		height: 13px;
		border-radius: 2px;
		display: inline-block;
	}
	.curva-sw {
		height: 3px;
		background: #2a2a22;
	}
	.lluvia-sw {
		background: rgba(58, 107, 138, 0.55);
	}
	.riego-sw {
		background: #3f7d54;
		border-radius: 50%;
	}
	.sw-verde {
		background: rgba(76, 122, 90, 0.25);
	}
	.sw-ambar {
		background: rgba(196, 142, 46, 0.3);
	}
	.sw-roja {
		background: rgba(180, 74, 62, 0.28);
	}

	.tabla {
		margin: 8px 0 44px;
	}
	.scroll {
		overflow-x: auto;
	}
	table {
		width: 100%;
		border-collapse: collapse;
		font-size: 0.88rem;
	}
	th,
	td {
		text-align: left;
		padding: 9px 12px 9px 0;
		border-bottom: 1px solid #e2e0d6;
		white-space: nowrap;
	}
	th {
		font-size: 0.72rem;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		color: #8a887c;
		font-weight: 600;
	}
	th.num,
	td.num {
		text-align: right;
		font-variant-numeric: tabular-nums;
	}
	.esp em {
		font-size: 0.86rem;
	}
	.comun {
		font-size: 0.78rem;
		color: #8a887c;
	}
	tr.muerto {
		opacity: 0.55;
	}
	.pill {
		display: inline-block;
		font-size: 0.75rem;
		padding: 2px 8px;
		border-radius: 999px;
		border: 1px solid transparent;
	}
	.e-feliz {
		background: rgba(63, 125, 84, 0.14);
		color: #2f6042;
	}
	.e-bien {
		background: rgba(120, 150, 90, 0.16);
		color: #57703a;
	}
	.e-sed {
		background: rgba(196, 142, 46, 0.16);
		color: #8a6118;
	}
	.e-crit {
		background: rgba(180, 74, 62, 0.16);
		color: #93362c;
	}
	.e-muerto {
		background: #ecebe4;
		color: #6a685d;
	}

	.nota {
		max-width: 72ch;
		border-top: 1px solid #d8d6cc;
		padding-top: 24px;
	}
	.nota p {
		font-size: 0.9rem;
		color: #454339;
	}
	.vacio {
		color: #8a887c;
		font-style: italic;
	}
	.pie {
		margin-top: 40px;
	}
	.pie a {
		color: #6a685d;
		font-size: 0.9rem;
		text-decoration: none;
		border-bottom: 1px solid #c9c7bb;
	}
</style>
