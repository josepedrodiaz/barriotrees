# QR de los árboles

Códigos QR para las chapitas físicas de la plaza.

## Qué hay acá

- `jacarandas/jacaranda-01.png` … `-10.png` — un QR por árbol, alta resolución (900px), para imprimir.
- `jacarandas/jacaranda-01.svg` … `-10.svg` — la versión vectorial (imprime nítido a cualquier tamaño).
- `hoja-imprimible.html` — abrilo en el navegador y tocá **Imprimir**: salen las 10 chapitas etiquetadas y con línea de corte, listas para colgar.

## A dónde apunta cada QR

Hoy apuntan a la **demo**, con el árbol ya abierto:

```
https://josepedrodiaz.github.io/barriotrees/demo.html?t=<N>
```

Así, escanear la chapita del jacarandá #3 abre ese árbol en la maqueta (sirve para probar en vivo el sábado).

## Importante

Estos son **QR de demo**. Cuando la app real esté hecha, los QR definitivos los genera el **admin** (es una función del MVP) apuntando al dominio final. Ahí se reimprimen — reemplazar el QR es solo cambiar la chapita.

## Regenerar

```bash
cd <scratchpad con qrcode instalado>
node gen.js   # usa la librería npm `qrcode`
```

Para cambiar la URL base, editá `BASE` en `gen.js`.
