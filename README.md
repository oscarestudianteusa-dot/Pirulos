# Pirulo's

Sistema de gestión para **Pirulo's**, local de comida rápida en Santiago.
Dueño: Miguel · Desarrollo: Pipo (JQ Soluciones).

Ver [CLAUDE.md](CLAUDE.md) para el contexto completo, las restricciones técnicas y las fases.

## Estado actual

| | |
|---|---|
| Catálogo digitalizado | ✅ 8 categorías, 90 productos |
| Prototipo visual de la carta | ✅ navegable |
| Impresión WebUSB | 🟡 página de prueba lista — **falta probarla en la tablet** |
| Carta real (Next.js + Supabase) | ⬜ no empezada |
| Pantalla de comandas en la tablet | ⬜ no empezada |

**Lo próximo es una sola cosa**: correr la prueba de impresión en la tablet del local.
Bloquea todo lo demás. Instrucciones en [docs/impresion.md](docs/impresion.md).

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
                       La prueba de impresión WebUSB. Se abre en Chrome en la tablet,
                       con la impresora enchufada por USB.
Fotos Carta/           Las 11 fotos de la carta física de las que salió todo.
```

## Ver el prototipo

Sin instalar nada: abrir `docs/mockup/carta.html` en el navegador.

Publicado: **https://oscarestudianteusa-dot.github.io/Pirulos/**

## Probar la impresora

Desde **Chrome en la tablet** del local, con la impresora conectada por USB:

**https://oscarestudianteusa-dot.github.io/Pirulos/prueba-impresion.html**

Tiene que ser Chrome en Android y tiene que ser por `https://`: WebUSB no funciona de otra forma.

## Reglas importantes

- **Precios en pesos chilenos enteros.** Nunca decimales ni floats.
- **No inventar datos del negocio.** Si falta un precio o un dato, va a `data/DUDAS.md`,
  no al código.
- Todo el texto de la interfaz en español chileno.
