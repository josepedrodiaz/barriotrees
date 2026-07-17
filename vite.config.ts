import { defineConfig } from 'vitest/config';
import adapter from '@sveltejs/adapter-auto';
import { sveltekit } from '@sveltejs/kit/vite';
import { SvelteKitPWA } from '@vite-pwa/sveltekit';

export default defineConfig({
	plugins: [
		sveltekit({
			compilerOptions: {
				// Force runes mode for the project, except for libraries. Can be removed in svelte 6.
				runes: ({ filename }) =>
					filename.split(/[/\\]/).includes('node_modules') ? undefined : true
			},

			// adapter-auto only supports some environments, see https://svelte.dev/docs/kit/adapter-auto for a list.
			// If your environment is not supported, or you settled on a specific environment, switch out the adapter.
			// See https://svelte.dev/docs/kit/adapters for more information about adapters.
			adapter: adapter()
		}),
		SvelteKitPWA({
			registerType: 'autoUpdate',
			manifest: {
				name: 'Árboles Gigantes',
				short_name: 'Árboles',
				description:
					'Regá los árboles jóvenes de la Plaza Gigante del Oeste, sumá puntos y ayudalos a hacerse gigantes.',
				lang: 'es',
				start_url: '/',
				scope: '/',
				display: 'standalone',
				orientation: 'portrait',
				// Los colores del sistema visual (decisión 21): el splash y la barra
				// del sistema salen en el violeta del panel, no en blanco.
				background_color: '#221c36',
				theme_color: '#221c36',
				icons: [
					{ src: '/iconos/icon-192.png', sizes: '192x192', type: 'image/png' },
					{ src: '/iconos/icon-512.png', sizes: '512x512', type: 'image/png' },
					// El maskable deja aire alrededor: Android lo recorta en círculo.
					{
						src: '/iconos/maskable-512.png',
						sizes: '512x512',
						type: 'image/png',
						purpose: 'maskable'
					}
				]
			},
			workbox: {
				// Precachea el shell entero (JS, CSS, fuentes, íconos): la app abre al
				// toque aunque la señal de la plaza esté floja. Los datos siguen
				// viniendo de la red (sin conexión real es v2, decisión 13).
				globPatterns: ['client/**/*.{js,css,ico,png,svg,woff2,webmanifest}']
			}
		})
	],
	test: {
		expect: { requireAssertions: true },
		projects: [
			{
				extends: './vite.config.ts',
				test: {
					name: 'server',
					environment: 'node',
					include: ['src/**/*.{test,spec}.{js,ts}'],
					exclude: ['src/**/*.svelte.{test,spec}.{js,ts}']
				}
			}
		]
	}
});
