import { supabase } from '$lib/supabase';

// El catálogo es público a propósito: el que todavía no tiene cuenta también
// puede ver qué hay para ganar. Lo suyo (lo ganado y el avance) lo suma la
// página cuando hay sesión.
export const load = async () => {
	const [{ data: insignias }, { data: config }] = await Promise.all([
		supabase
			.from('insignias')
			.select('id, tipo, orden, nombre, umbral_puntos, criterio, copy_desbloqueo, es_pin')
			.eq('activa', true)
			.order('orden', { ascending: true, nullsFirst: false }),
		supabase.from('config').select('clave, valor')
	]);

	const objetivos: Record<string, number> = {};
	for (const c of config ?? []) objetivos[c.clave] = Number(c.valor);

	return {
		escalera: (insignias ?? []).filter((i) => i.tipo === 'escalera'),
		meritos: (insignias ?? []).filter((i) => i.tipo === 'merito'),
		objetivos,
		// A dónde apunta el QR de canje. Sale de la base: si cambia el dominio,
		// los QR nuevos salen bien sin tocar código (igual que las chapitas).
		urlBase: String(
			(config ?? []).find((c) => c.clave === 'url_base')?.valor ??
				'https://arboles-gigantes.vercel.app'
		)
	};
};
