<script lang="ts">
	// El pin: una medalla dorada con un balde volcando agua sobre un brote.
	// No es un ícono decorativo — es el objeto físico que la comisión entrega en
	// mano (decisión: los logros permanentes se dan como pines reales). Portado
	// tal cual de tools/demo.html (pinSVG).
	interface Props {
		px?: number;
		alt?: string;
	}
	let { px = 96, alt }: Props = $props();
	const alto = $derived(Math.round((px * 128) / 120));
</script>

<svg
	class="pin"
	viewBox="0 0 120 128"
	width={px}
	height={alto}
	role={alt ? 'img' : 'presentation'}
	aria-label={alt}
	aria-hidden={alt ? undefined : 'true'}
>
	<rect x="56" y="6" width="8" height="15" rx="3" fill="#c99a1e" />
	<circle cx="60" cy="9" r="6" fill="#F5C542" stroke="#8a6a10" stroke-width="2" />
	<circle cx="60" cy="72" r="54" fill="#F5C542" stroke="#8a6a10" stroke-width="4" />
	<circle cx="60" cy="72" r="54" fill="none" stroke="#ffe08a" stroke-width="3" opacity=".6" />
	<circle cx="60" cy="72" r="43" fill="#2B2542" stroke="#14101f" stroke-width="3" />
	<circle cx="60" cy="66" r="31" fill="#3FA9F5" opacity=".10" />

	<!-- suelo + brote que recibe el agua -->
	<ellipse cx="66" cy="99" rx="14" ry="4.5" fill="#6E4326" />
	<rect x="63.5" y="85" width="5" height="14" fill="#2b9350" />
	<path
		d="M66 89 C 54 83, 48 90, 58 95 C 66 96, 67 92, 66 89 Z"
		fill="#46C36A"
		stroke="#2b9350"
		stroke-width="1.5"
	/>
	<path
		d="M66 87 C 78 81, 84 88, 74 93 C 66 94, 65 90, 66 87 Z"
		fill="#46C36A"
		stroke="#2b9350"
		stroke-width="1.5"
	/>

	<!-- balde volcando -->
	<g transform="rotate(40 48 60)">
		<path d="M36 50 Q48 33 60 50" fill="none" stroke="#8a919e" stroke-width="3.5" />
		<polygon points="33,46 63,46 61,53 35,53" fill="#d2d8e0" stroke="#6f7683" stroke-width="2" />
		<polygon points="35,53 61,53 56,75 40,75" fill="#b6bec9" stroke="#6f7683" stroke-width="2" />
		<polygon points="52,53 61,53 56,75 50,75" fill="#9aa3b0" opacity=".65" />
	</g>

	<!-- el chorro cayendo sobre el brote -->
	<path
		d="M69 57 C 73 68, 71 79, 66 86"
		fill="none"
		stroke="#3FA9F5"
		stroke-width="5"
		stroke-linecap="round"
	/>
	<path
		d="M69 57 C 73 68, 71 79, 66 86"
		fill="none"
		stroke="#bfe4ff"
		stroke-width="1.6"
		stroke-linecap="round"
		opacity=".8"
	/>
	<circle cx="70" cy="64" r="2.2" fill="#e8f5ff" />
	<circle cx="70.5" cy="74" r="1.8" fill="#e8f5ff" />
	<path
		d="M56 91 Q66 97 76 91"
		fill="none"
		stroke="#7fc4ff"
		stroke-width="2.5"
		opacity=".7"
		stroke-linecap="round"
	/>

	<!-- brillos -->
	<text x="26" y="54" font-size="12" fill="#fff" opacity=".9">✦</text>
	<text x="89" y="64" font-size="9" fill="#fff" opacity=".85">✦</text>
	<path
		d="M32 44 A54 54 0 0 1 90 40"
		fill="none"
		stroke="#fff"
		stroke-width="3"
		opacity=".3"
		stroke-linecap="round"
	/>
</svg>

<style>
	.pin {
		display: block;
		margin: 0 auto;
		animation: pinglow 1.6s ease-in-out infinite;
	}
	@keyframes pinglow {
		0%,
		100% {
			filter: drop-shadow(2px 3px 0 rgba(0, 0, 0, 0.3)) drop-shadow(0 0 3px rgba(245, 197, 66, 0.5));
		}
		50% {
			filter: drop-shadow(2px 3px 0 rgba(0, 0, 0, 0.3))
				drop-shadow(0 0 13px rgba(245, 197, 66, 0.9));
		}
	}
	@media (prefers-reduced-motion: reduce) {
		.pin {
			animation: none;
		}
	}
</style>
