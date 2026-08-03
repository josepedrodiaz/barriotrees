import { supabase } from '$lib/supabase';
import {
	serieDiaria,
	diasDeEstres,
	diasCriticos,
	coberturaVerde,
	etcAcumulada,
	et0Acumulada,
	lluviaAcumulada,
	aguaAplicadaLitros,
	tasaSupervivencia,
	type DiaClima
} from '$lib/domain/agronomia';
import { BANDAS_DEFAULT, type Bandas } from '$lib/domain/estado';

// Panel agronómico: reconstruye el balance hídrico de cada árbol a partir de los
// riegos (juego) y el clima (Open-Meteo), y saca las métricas serias. Todo el
// cálculo pesado son funciones puras del dominio; acá solo se juntan los datos.
export const load = async () => {
	const [
		{ data: clima },
		{ data: arboles },
		{ data: especies },
		{ data: riegos },
		{ data: config }
	] = await Promise.all([
		supabase.from('clima_diario').select('fecha, et0_mm, lluvia_mm, temp_max').order('fecha'),
		supabase
			.from('v_arboles_estado')
			.select(
				'id, codigo, nombre, especie_id, especie_nombre, especie_cientifico, estado, f_efectiva, fecha_defuncion, fecha_plantacion, en_programa'
			)
			.order('codigo'),
		supabase.from('especies').select('id, kc'),
		supabase.from('riegos').select('arbol_id, creado_en'),
		supabase.from('config').select('clave, valor')
	]);

	const cfg = Object.fromEntries((config ?? []).map((c) => [c.clave, c.valor]));
	const et0Ref = Number(cfg['et0_referencia_mm'] ?? 4.5);
	const bandas: Bandas = {
		feliz: Number(cfg['banda_feliz'] ?? BANDAS_DEFAULT.feliz),
		bien: Number(cfg['banda_bien'] ?? BANDAS_DEFAULT.bien),
		sediento: Number(cfg['banda_sediento'] ?? BANDAS_DEFAULT.sediento)
	};

	const climaSerie: DiaClima[] = (clima ?? []).map((c) => ({
		fecha: c.fecha,
		et0: Number(c.et0_mm),
		lluvia: Number(c.lluvia_mm),
		tempMax: c.temp_max
	}));

	const kcDe = new Map((especies ?? []).map((e) => [e.id, Number(e.kc)]));

	// Riegos por árbol, como fechas (YYYY-MM-DD).
	const riegosPorArbol = new Map<string, string[]>();
	for (const r of riegos ?? []) {
		if (!r.arbol_id) continue;
		const lista = riegosPorArbol.get(r.arbol_id) ?? [];
		lista.push(r.creado_en.slice(0, 10));
		riegosPorArbol.set(r.arbol_id, lista);
	}

	// Solo árboles del programa (los reales que se cuidan); las preexistencias no.
	const delPrograma = (arboles ?? []).filter((a) => a.en_programa);

	const porArbol = delPrograma.map((a) => {
		const fechasRiego = riegosPorArbol.get(a.id!) ?? [];
		const f = Number(a.f_efectiva ?? 2);
		const kc = kcDe.get(a.especie_id!) ?? 0.7;
		const serie = serieDiaria(climaSerie, fechasRiego, f, et0Ref, bandas);
		const ultimoRiego = fechasRiego.length ? fechasRiego.slice().sort().at(-1)! : null;
		return {
			codigo: a.codigo!,
			nombre: a.nombre,
			especie: a.especie_nombre,
			especieCientifico: a.especie_cientifico,
			estado: a.estado,
			muerto: !!a.fecha_defuncion,
			fechaDefuncion: a.fecha_defuncion,
			f,
			umbralSediento: f * bandas.bien * et0Ref,
			umbralCritico: f * bandas.sediento * et0Ref,
			diasEstres: diasDeEstres(serie),
			diasCriticos: diasCriticos(serie),
			cobertura: coberturaVerde(serie),
			riegos: fechasRiego.length,
			ultimoRiego,
			etc: etcAcumulada(climaSerie, kc),
			serie
		};
	});

	const total = porArbol.length;
	const muertos = porArbol.filter((a) => a.muerto).length;
	const vivos = total - muertos;
	const riegosTotales = porArbol.reduce((s, a) => s + a.riegos, 0);

	return {
		desde: climaSerie[0]?.fecha ?? null,
		hasta: climaSerie.at(-1)?.fecha ?? null,
		dias: climaSerie.length,
		et0Ref,
		plaza: {
			total,
			vivos,
			muertos,
			supervivencia: tasaSupervivencia(vivos, total),
			riegosTotales,
			aguaLitros: aguaAplicadaLitros(riegosTotales),
			lluviaAcum: lluviaAcumulada(climaSerie),
			et0Acum: et0Acumulada(climaSerie),
			estresPromedio: total
				? Math.round((porArbol.reduce((s, a) => s + a.diasEstres, 0) / total) * 10) / 10
				: 0
		},
		arboles: porArbol
	};
};
