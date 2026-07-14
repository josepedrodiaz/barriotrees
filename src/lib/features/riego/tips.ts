// Tips que se muestran durante la pantalla "Regando…" (decisión 19: la espera
// mínima educa). Rotan al azar; con el tiempo los curan las comisiones.

export const TIPS: string[] = [
	'Regá despacio y al pie: el agua que corre rápido no llega a las raíces.',
	'Un balde entero por árbol joven. Mejor mucho de una vez que poquito seguido.',
	'El mejor horario para regar: temprano a la mañana o después del atardecer.',
	'Si ves hormigas subiendo por el tronco, avisá — atacan a los árboles jóvenes.',
	'El tutor (el palo) sostiene al arbolito mientras crece. Si está flojo, avisá.',
	'Un jacarandá joven necesita agua cada 2 días en verano. De grande, casi nada.',
	'La tierra con mantillo (hojas, corteza) guarda la humedad mucho más tiempo.',
	'No riegues las hojas: el agua va al pie, donde están las raíces.'
];

export function tipAlAzar(): string {
	return TIPS[Math.floor(Math.random() * TIPS.length)];
}
