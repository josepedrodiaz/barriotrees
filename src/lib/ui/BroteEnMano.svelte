<script lang="ts">
	// Una mano sosteniendo un brote. Portado de tools/demo.html (handSproutSVG).
	interface Props {
		px?: number;
	}
	let { px = 32 }: Props = $props();
</script>

<svg viewBox="0 0 32 32" width={px} height={px} aria-hidden="true">
	<rect x="15" y="9" width="2" height="9" fill="#2b9350" />
	<path
		d="M16 11 C 10 7, 5 11, 11 14 C 14 15, 16 13, 16 11 Z"
		fill="#46C36A"
		stroke="#2b9350"
		stroke-width="1"
	/>
	<path
		d="M16 10 C 22 6, 27 10, 21 13 C 18 14, 16 12, 16 10 Z"
		fill="#46C36A"
		stroke="#2b9350"
		stroke-width="1"
	/>
	<path
		d="M6 21 Q 5 18 8 19 L 13 20 Q 16 17 19 20 L 24 19 Q 27 18 26 21 L 25 26 Q 16 31 7 26 Z"
		fill="#E8B98A"
		stroke="#a97c4f"
		stroke-width="1.3"
	/>
</svg>
