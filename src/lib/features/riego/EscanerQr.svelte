<script lang="ts">
	import { onMount } from 'svelte';
	import { codigoDesdeQr } from './qr';

	interface Props {
		/** Se llama con el código del árbol apenas se lee una chapita válida. */
		onCodigo: (codigo: string) => void;
		onCancelar: () => void;
	}
	let { onCodigo, onCancelar }: Props = $props();

	let video: HTMLVideoElement;
	let estado: 'pidiendo' | 'escaneando' | 'sin_camara' | 'sin_permiso' = $state('pidiendo');
	// Un QR ajeno no corta el escaneo: se avisa y se sigue buscando la chapita.
	let ajeno = $state(false);

	let stream: MediaStream | null = null;
	let corriendo = true;

	onMount(() => {
		arrancar();
		return () => {
			corriendo = false;
			stream?.getTracks().forEach((t) => t.stop());
		};
	});

	async function arrancar() {
		if (!navigator.mediaDevices?.getUserMedia) {
			estado = 'sin_camara';
			return;
		}
		try {
			// La cámara de atrás: es la que apunta a la chapita.
			stream = await navigator.mediaDevices.getUserMedia({
				video: { facingMode: 'environment' }
			});
		} catch (e) {
			estado = (e as DOMException).name === 'NotAllowedError' ? 'sin_permiso' : 'sin_camara';
			return;
		}
		video.srcObject = stream;
		// iOS solo reproduce inline y con el gesto que ya hubo (el botón).
		video.setAttribute('playsinline', 'true');
		await video.play();
		estado = 'escaneando';

		// jsQR se carga acá y no arriba: la mayoría de las pantallas nunca abren
		// la cámara, y así no cargan el decodificador.
		const jsQR = (await import('jsqr')).default;
		const lienzo = document.createElement('canvas');
		const ctx = lienzo.getContext('2d', { willReadFrequently: true })!;

		const mirar = () => {
			if (!corriendo) return;
			if (video.readyState === video.HAVE_ENOUGH_DATA) {
				lienzo.width = video.videoWidth;
				lienzo.height = video.videoHeight;
				ctx.drawImage(video, 0, 0, lienzo.width, lienzo.height);
				const img = ctx.getImageData(0, 0, lienzo.width, lienzo.height);
				const leido = jsQR(img.data, img.width, img.height, { inversionAttempts: 'dontInvert' });
				if (leido) {
					const codigo = codigoDesdeQr(leido.data);
					if (codigo) {
						corriendo = false;
						onCodigo(codigo);
						return;
					}
					ajeno = true;
				}
			}
			requestAnimationFrame(mirar);
		};
		requestAnimationFrame(mirar);
	}
</script>

<div class="escaner">
	<video bind:this={video} muted playsinline class:visible={estado === 'escaneando'}></video>

	{#if estado === 'escaneando'}
		<div class="marco">
			<span class="esq tl"></span><span class="esq tr"></span>
			<span class="esq bl"></span><span class="esq br"></span>
		</div>
		<p class="ayuda">
			{#if ajeno}Ese QR no es de un árbol. Apuntá a la chapita.{:else}Apuntá a la chapita del árbol{/if}
		</p>
	{:else if estado === 'pidiendo'}
		<p class="msg">Pidiendo la cámara…</p>
	{:else if estado === 'sin_permiso'}
		<div class="msg">
			<h2>SIN CÁMARA NO SE PUEDE ESCANEAR</h2>
			<p>Activá el permiso de cámara del navegador y probá de nuevo.</p>
		</div>
	{:else}
		<div class="msg">
			<h2>NO ENCONTRAMOS LA CÁMARA</h2>
			<p>Probá desde el teléfono, parado al lado del árbol.</p>
		</div>
	{/if}

	<button class="btn ghost wide cancelar" onclick={onCancelar}>Cancelar</button>
</div>

<style>
	.escaner {
		position: fixed;
		inset: 0;
		z-index: 90;
		background: #0c0a14;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		padding: 22px;
		gap: 18px;
	}
	video {
		position: absolute;
		inset: 0;
		width: 100%;
		height: 100%;
		object-fit: cover;
		opacity: 0;
	}
	video.visible {
		opacity: 1;
	}
	/* El recuadro con esquinas verdes, como la mira de la demo. */
	.marco {
		position: relative;
		width: min(70vw, 260px);
		aspect-ratio: 1;
		z-index: 2;
	}
	.esq {
		position: absolute;
		width: 34px;
		height: 34px;
		border: 5px solid var(--feliz);
	}
	.tl {
		top: 0;
		left: 0;
		border-right: none;
		border-bottom: none;
	}
	.tr {
		top: 0;
		right: 0;
		border-left: none;
		border-bottom: none;
	}
	.bl {
		bottom: 0;
		left: 0;
		border-right: none;
		border-top: none;
	}
	.br {
		bottom: 0;
		right: 0;
		border-left: none;
		border-top: none;
	}
	.ayuda {
		position: relative;
		z-index: 2;
		color: #fff;
		text-align: center;
		font-size: 18px;
		background: rgba(8, 6, 16, 0.7);
		padding: 8px 12px;
		margin: 0;
	}
	.msg {
		position: relative;
		z-index: 2;
		color: var(--ink);
		text-align: center;
		max-width: 30ch;
	}
	.msg h2 {
		color: var(--sed);
	}
	.cancelar {
		position: relative;
		z-index: 2;
		max-width: 260px;
	}
</style>
