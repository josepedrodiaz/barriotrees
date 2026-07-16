// Tips que se muestran durante la pantalla "Regando…" (decisión 19: la espera
// mínima educa). Van rotando mientras dura el riego.
//
// Son los de la demo: hablan del jacarandá concreto de la galería, no del
// riego en abstracto. Con el tiempo los curan las comisiones.

export const TIPS: string[] = [
	'Los jacarandás jóvenes toman agua cada ~2 días en verano.',
	'Regá despacio en la base: así el agua llega a la raíz.',
	'Con un balde alcanza. De más no ayuda a un arbolito.',
	'En primavera se llena de flores violeta. Por algo La Plata es su ciudad.',
	'Mejor temprano o al atardecer, nunca al sol del mediodía.',
	'El jacarandá es oriundo del noroeste argentino y de Bolivia.',
	'Si la tierra está seca dos dedos abajo, tiene sed.',
	'De grande llega a 10-15 metros. Hoy arranca chiquito, con vos.',
	'Sus primeras flores tardan años: hoy plantás esa espera.',
	'Un buen riego moja la tierra, no las hojas.',
	'Si ves hormigas subiendo por el tronco, avisá: atacan a los árboles jóvenes.',
	'El tutor (el palo) sostiene al arbolito mientras crece. Si está flojo, avisá.'
];

export function tipAlAzar(): string {
	return TIPS[Math.floor(Math.random() * TIPS.length)];
}

/** Otro tip, nunca el mismo que se está viendo. */
export function otroTip(actual: string): string {
	if (TIPS.length < 2) return TIPS[0];
	let t = actual;
	while (t === actual) t = tipAlAzar();
	return t;
}
