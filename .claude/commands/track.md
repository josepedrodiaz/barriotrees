---
description: Reporte HTML de tiempo invertido por ticket BT-* leyendo los worklogs de Jira, separado por dimensión humano/claude. Genera torta + barras apiladas + tabla y abre en browser.
argument-hint: "[rango: sprint|semana|YYYY-MM-DD..YYYY-MM-DD] (default: sprint activo)"
---

# /track — Reporte de tiempo por ticket

Generá un reporte HTML del tiempo invertido en cada ticket BT-*, leyendo los **worklogs** de Jira. Cada worklog tiene una dimensión según el prefijo de su comment:

- comment empieza con `[claude]` → dimensión **claude** (Claude ejecutando trabajo)
- comment empieza con `[humano]`, o sin prefijo (worklogs viejos) → dimensión **humano**

Las dimensiones pueden solaparse en el tiempo: humano y claude se muestran separadas y el total es la suma de ambas (horas de trabajo registradas, no horas de reloj).

## Argumento

`$ARGUMENTS` puede ser:
- vacío → sprint activo del board BT
- `sprint` → sprint activo
- `semana` → últimos 7 días
- `YYYY-MM-DD..YYYY-MM-DD` → rango custom
- `BT-123` o lista `BT-123,BT-124` → tickets puntuales

## Pasos a ejecutar

1. **Resolver el rango de tickets:**
   - Para sprint activo: `mcp__mcp-atlassian__jira_search` con JQL `project = BT AND sprint in openSprints()`
   - Para semana: JQL `project = BT AND updated >= -7d`
   - Para fechas: JQL con `updated >= "YYYY-MM-DD" AND updated <= "YYYY-MM-DD"`
   - Para lista de keys: `key in (BT-123, BT-124)`
   - Pedir solo campos: `summary, status, assignee, created, updated`

2. **Traer worklogs por ticket:**
   - `mcp__mcp-atlassian__jira_get_worklog` con cada issue key
   - Filtrar por rango usando el campo `started` de cada worklog (para sprint activo, usar las fechas del sprint; para semana/custom, el rango pedido)

3. **Clasificar y sumar:**
   - Dimensión del worklog: regex `^\[(humano|claude)\]` sobre el comment; sin match → `humano`
   - Minutos = `timeSpentSeconds / 60`
   - Por ticket: `{humano, claude, total}`
   - Por día y dimensión (para barras apiladas): fecha de `started` → `{ "2026-05-20": {humano: 60, claude: 145}, ... }`

4. **Generar HTML en `/tmp/track-tiempo-reporte.html`** con la plantilla de abajo, reemplazando los placeholders:
   - `{{TITULO}}` → ej. "Sprint 1 — sprint-1/home-secciones"
   - `{{RANGO}}` → ej. "2026-05-19 → 2026-05-26 · N tickets"
   - `{{TOTAL_HORAS}}` / `{{HUMANO_HORAS}}` / `{{CLAUDE_HORAS}}` → sumas formateadas `Xh YYm`
   - `{{PIE_LABELS}}` → JSON array `["BT-123: Hero", "BT-124: Home", ...]`
   - `{{PIE_DATA}}` → JSON array de minutos totales `[135, 270, ...]`
   - `{{BARS_LABELS}}` → JSON array de fechas `["2026-05-20", ...]`
   - `{{BARS_HUMANO}}` / `{{BARS_CLAUDE}}` → JSON arrays de minutos por día de cada dimensión
   - `{{TABLA_FILAS}}` → HTML `<tr>...</tr>` por ticket con: key (link a Jira), summary, estado actual, humano, claude, total

5. **Abrir el HTML:**
   - `open /tmp/track-tiempo-reporte.html` (macOS)

6. **Resumen en chat:** una línea sola: "9h 15m esta semana (3h humano + 6h 15m claude), top BT-124 (4h 30m)."

## Plantilla HTML

```html
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<title>{{TITULO}} — tiempo</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>
<style>
  * { box-sizing: border-box; }
  body { font: 14px/1.5 -apple-system, system-ui, sans-serif; max-width: 1100px; margin: 0 auto; padding: 32px; color: #1a1a1a; background: #fafafa; }
  h1 { font-size: 22px; margin: 0 0 4px; }
  .meta { color: #666; font-size: 13px; margin-bottom: 24px; }
  .cards { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; margin-bottom: 24px; }
  .card { background: #fff; padding: 16px; border-radius: 8px; border: 1px solid #e5e5e5; }
  .card .num { font-size: 28px; font-weight: 600; }
  .card .lbl { font-size: 12px; color: #666; text-transform: uppercase; letter-spacing: 0.5px; }
  .card.humano .num { color: #0a66c2; }
  .card.claude .num { color: #7c3aed; }
  .charts { display: grid; grid-template-columns: 1fr 1.4fr; gap: 16px; margin-bottom: 24px; }
  .chart-box { background: #fff; padding: 16px; border-radius: 8px; border: 1px solid #e5e5e5; }
  table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 8px; overflow: hidden; border: 1px solid #e5e5e5; }
  th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid #f0f0f0; }
  th { background: #f5f5f5; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; color: #555; }
  td.t { text-align: right; font-variant-numeric: tabular-nums; }
  td.t.total { font-weight: 600; }
  a { color: #0a66c2; text-decoration: none; }
  a:hover { text-decoration: underline; }
  .status { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 11px; background: #eef; color: #335; }
  .status.activo { background: #e8f5e8; color: #2a6a2a; }
</style>
</head>
<body>
<h1>{{TITULO}}</h1>
<div class="meta">{{RANGO}}</div>

<div class="cards">
  <div class="card"><div class="num">{{TOTAL_HORAS}}</div><div class="lbl">Total registrado</div></div>
  <div class="card humano"><div class="num">{{HUMANO_HORAS}}</div><div class="lbl">Humano</div></div>
  <div class="card claude"><div class="num">{{CLAUDE_HORAS}}</div><div class="lbl">Claude</div></div>
</div>

<div class="charts">
  <div class="chart-box"><canvas id="pie"></canvas></div>
  <div class="chart-box"><canvas id="bars"></canvas></div>
</div>

<table>
  <thead><tr><th>Ticket</th><th>Título</th><th>Estado</th><th style="text-align:right">Humano</th><th style="text-align:right">Claude</th><th style="text-align:right">Total</th></tr></thead>
  <tbody>{{TABLA_FILAS}}</tbody>
</table>

<script>
const fmt = m => { const h = Math.floor(m/60), mm = m%60; return h ? `${h}h ${mm}m` : `${mm}m`; };

new Chart(document.getElementById('pie'), {
  type: 'doughnut',
  data: {
    labels: {{PIE_LABELS}},
    datasets: [{ data: {{PIE_DATA}}, backgroundColor: ['#0a66c2','#E30202','#2a6a2a','#b8860b','#6a2a6a','#666','#d97706','#0891b2','#7c3aed','#be185d'] }]
  },
  options: {
    plugins: {
      legend: { position: 'right', labels: { font: { size: 11 } } },
      tooltip: { callbacks: { label: ctx => `${ctx.label}: ${fmt(ctx.parsed)}` } },
      title: { display: true, text: 'Total por ticket' }
    }
  }
});

new Chart(document.getElementById('bars'), {
  type: 'bar',
  data: {
    labels: {{BARS_LABELS}},
    datasets: [
      { label: 'humano', data: {{BARS_HUMANO}}, backgroundColor: '#0a66c2' },
      { label: 'claude', data: {{BARS_CLAUDE}}, backgroundColor: '#7c3aed' }
    ]
  },
  options: {
    plugins: {
      tooltip: { callbacks: { label: ctx => `${ctx.dataset.label}: ${fmt(ctx.parsed.y)}` } },
      title: { display: true, text: 'Tiempo por día' }
    },
    scales: { x: { stacked: true }, y: { stacked: true, ticks: { callback: v => fmt(v) } } }
  }
});
</script>
</body>
</html>
```

## Notas

- Los worklogs son la fuente de verdad — los sube el propio módulo al cerrar intervalos (`/track-stop`, cambio de ticket, o el flush del SessionStart hook).
- Worklogs sin prefijo `[humano]`/`[claude]` son anteriores al split de dimensiones → cuentan como humano.
- Si un ticket no tiene worklogs en el rango → no aparece en el reporte (no inventar tiempo).
- Puede haber intervalos aún no sincronizados en `.claude/tiempo/state.json` (`timer.py pending-sync`); si hay pendientes, avisarlo en el resumen de chat.
