<script lang="ts">
	import QRCode from 'qrcode';
	import Pin from '$lib/ui/Pin.svelte';

	interface Props {
		nombre: string;
		token: string;
		urlBase: string;
	}
	let { nombre, token, urlBase }: Props = $props();

	let qr = $state('');

	// El QR lleva a la página del validador. Así el de la comisión escanea con
	// la cámara del teléfono, como cualquiera, y no hace falta una app aparte.
	const url = $derived(`${urlBase}/admin/canje/${token}`);

	$effect(() => {
		QRCode.toDataURL(url, { errorCorrectionLevel: 'M', margin: 1, width: 320 }).then(
			(d) => (qr = d)
		);
	});
</script>

<div class="canje panel">
	<div class="pin"><Pin px={64} /></div>
	<div class="nombre">{nombre.toUpperCase()}</div>
	<div class="qr">
		{#if qr}
			<img src={qr} alt="QR para canjear el pin de {nombre}" />
		{:else}
			<div class="hueco"></div>
		{/if}
	</div>
	<p class="como">
		Mostrale esta pantalla a quien te entrega el pin. La escanea, y el pin es tuyo.
	</p>
</div>

<style>
	.canje {
		padding: 16px 14px;
		text-align: center;
		margin: 10px 0;
	}
	.pin {
		margin-bottom: 8px;
	}
	.nombre {
		font-family: var(--pixel);
		font-size: 11px;
		line-height: 1.5;
		color: var(--gold);
		text-shadow: 2px 2px 0 #6b4d00;
		margin-bottom: 12px;
	}
	/* El QR va sobre blanco sí o sí: sobre el violeta del panel, muchas cámaras
	   no lo leen. */
	.qr img,
	.hueco {
		width: 200px;
		height: 200px;
		display: block;
		margin: 0 auto;
		background: #fff;
		padding: 8px;
		border: 3px solid var(--edge-d);
	}
	.hueco {
		background: #ece8de;
	}
	.como {
		font-size: 16px;
		color: var(--dim);
		margin: 12px auto 0;
		max-width: 32ch;
	}
</style>
