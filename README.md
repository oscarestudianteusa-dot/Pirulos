# Pirulo's

Sistema de gestión para **Pirulo's**, local de comida rápida en Santiago.
Dueño: Miguel · Desarrollo: Pipo (JQ Soluciones).

Ver [CLAUDE.md](CLAUDE.md) para el contexto completo, las restricciones técnicas y las fases.

## Estado actual

| | |
|---|---|
| Catálogo digitalizado | ✅ 8 categorías, 90 productos |
| Prototipo visual de la carta | ✅ navegable |
| Impresión por Bluetooth | ✅ **probada en la impresora real** — imprime sola, reconecta sola, convive con Loyverse |
| Carta real (Next.js + Supabase) | ⬜ no empezada |
| Pantalla de comandas en la tablet | ⬜ no empezada |

**Fase 0 cerrada el 27/10/2026.** La comanda sale sola por Bluetooth, la tablet reconecta sin que
nadie toque nada, y las tildes salen bien. No queda ningún bloqueador técnico: lo próximo es
construir la carta. Detalles en [docs/impresion.md](docs/impresion.md).

## Qué hay acá

```
data/catalogo.json     El catálogo: categorías, productos, precios.
                       Fuente única de verdad. Se edita acá y la carta cambia.
data/DUDAS.md          Lo que falta confirmar con Miguel, en checklist.
docs/mockup/carta.html Prototipo navegable de la carta del cliente.
                       Un solo archivo, sin dependencias: se abre en cualquier navegador.
docs/impresion.md      Cómo llega un pedido de WhatsApp al papel: el flujo completo,
                       qué se descartó y por qué, y los pasos de la prueba en la tablet.
docs/prueba-impresion.html
                       La prueba de impresión. Se abre en Chrome en la tablet, con la
                       impresora ya emparejada por Bluetooth. Prueba los tres caminos
                       (Bluetooth SPP, BLE, USB) y que imprima sola.
Fotos Carta/           Las 11 fotos de la carta física de las que salió todo.
```

## Ver el prototipo

Sin instalar nada: abrir `docs/mockup/carta.html` en el navegador.

Publicado: **https://oscarestudianteusa-dot.github.io/Pirulos/**

## Probar la impresora

Desde **Chrome en la tablet** del local, con la impresora **ya emparejada por Bluetooth** en los
ajustes de Android:

**https://oscarestudianteusa-dot.github.io/Pirulos/prueba-impresion.html**

Tiene que ser **Chrome en Android 138 o superior** y tiene que ser por `https://`. Ninguna de las
APIs de impresión funciona de otra forma.

## Reglas importantes

- **Precios en pesos chilenos enteros.** Nunca decimales ni floats.
- **No inventar datos del negocio.** Si falta un precio o un dato, va a `data/DUDAS.md`,
  no al código.
- Todo el texto de la interfaz en español chileno.
