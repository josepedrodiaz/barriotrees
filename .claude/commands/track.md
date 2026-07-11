---
description: Reporte HTML de tiempo invertido por ticket BT-* leyendo el changelog de Jira. Genera torta + barras + tabla y abre en browser.
argument-hint: "[rango: sprint|semana|YYYY-MM-DD..YYYY-MM-DD] (default: sprint activo)"
---

# /track — Reporte de tiempo por ticket

Generá un reporte HTML del tiempo invertido en cada ticket BT-*, leyendo el changelog de Jira (no requiere worklog manual). El tiempo de un ticket = suma de intervalos en los que estuvo en estado "En curso".

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

2. **Traer changelogs en batch:**
   - `mcp__mcp-atlassian__jira_batch_get_changelogs` con los issue keys
   - Filtrar solo cambios del campo `status`

3. **Calcular tiempo en "En curso" por ticket:**
   - Para cada ticket, recorrer cambios de status ordenados por fecha
   - Cada vez que entra a "En curso" → guardar timestamp de inicio
   - Cada vez que sale de "En curso" → cerrar intervalo, sumar diff
   - Si el último estado es "En curso" → cerrar con `now()` (sigue activo)
   - Total ticket = suma de intervalos en minutos

4. **Agrupar por día también** (para gráfico de barras):
   - Por cada intervalo, distribuir minutos en los días que cruza
   - Resultado: `{ "2026-05-20": 145, "2026-05-21": 90, ... }`

5. **Generar HTML en `/tmp/track-tiempo-reporte.html`** con la plantilla de abajo, reemplazando los placeholders:
   - `{{TITULO}}` → ej. "Sprint 1 — sprint-1/home-secciones"
   - `{{RANGO}}` → ej. "2026-05-19 → 2026-05-26"
   - `{{TOTAL_HORAS}}` → suma total formateada `Xh YYm`
   - `{{TICKETS_COUNT}}` → cantidad de tickets con tiempo > 0
   - `{{PIE_LABELS}}` → JSON array `["BT-123: Hero", "BT-124: Home", ...]`
   - `{{PIE_DATA}}` → JSON array de minutos `[135, 270, ...]`
   - `{{BARS_LABELS}}` → JSON array de fechas `["2026-05-20", ...]`
   - `{{BARS_DATA}}` → JSON array de minutos por día
   - `{{TABLA_FILAS}}` → HTML `<tr>...</tr>` por ticket con: key (link a Jira), summary, tiempo, estado actual

6. **Abrir el HTML:**
   - `open /tmp/track-tiempo-reporte.html` (macOS)

7. **Resumen en chat:** una línea sola con total + ticket top: "7h 30m esta semana, top BT-124 (4h 30m)."

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
  .charts { display: grid; grid-template-columns: 1fr 1.4fr; gap: 16px; margin-bottom: 24px; }
  .chart-box { background: #fff; padding: 16px; border-radius: 8px; border: 1px solid #e5e5e5; }
  table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 8px; overflow: hidden; border: 1px solid #e5e5e5; }
  th, td { padding: 10px 12px; text-align: left; border-bottom: 1px solid #f0f0f0; }
  th { background: #f5f5f5; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; color: #555; }
  td.t { text-align: right; font-variant-numeric: tabular-nums; font-weight: 600; }
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
  <div class="card"><div class="num">{{TOTAL_HORAS}}</div><div class="lbl">Total invertido</div></div>
  <div class="card"><div class="num">{{TICKETS_COUNT}}</div><div class="lbl">Tickets activos</div></div>
  <div class="card"><div class="num">{{PROMEDIO_DIA}}</div><div class="lbl">Promedio por día</div></div>
</div>

<div class="charts">
  <div class="chart-box"><canvas id="pie"></canvas></div>
  <div class="chart-box"><canvas id="bars"></canvas></div>
</div>

<table>
  <thead><tr><th>Ticket</th><th>Título</th><th>Estado</th><th style="text-align:right">Tiempo</th></tr></thead>
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
      title: { display: true, text: 'Tiempo por ticket' }
    }
  }
});

new Chart(document.getElementById('bars'), {
  type: 'bar',
  data: {
    labels: {{BARS_LABELS}},
    datasets: [{ label: 'minutos', data: {{BARS_DATA}}, backgroundColor: '#0a66c2' }]
  },
  options: {
    plugins: {
      legend: { display: false },
      tooltip: { callbacks: { label: ctx => fmt(ctx.parsed.y) } },
      title: { display: true, text: 'Tiempo por día' }
    },
    scales: { y: { ticks: { callback: v => fmt(v) } } }
  }
});
</script>
</body>
</html>
```

## Notas

- El changelog es la fuente de verdad — no hay double-bookkeeping.
- Si un ticket nunca pasó por "En curso" → no aparece en el reporte (correcto: no se trabajó formalmente).
- Si notás un ticket faltante → significa que se olvidó moverlo a En curso (no inventar tiempo).
- Confirmar que el nombre del estado es exactamente "En curso" inspeccionando el primer changelog. Si difiere ("In Progress"), usar el real.
