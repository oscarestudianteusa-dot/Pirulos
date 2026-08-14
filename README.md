# Pirulo's

Sistema de gestión para **Pirulo's**, local de comida rápida en Santiago.
Dueño: Miguel · Desarrollo: Pipo (JQ Soluciones).

Ver [CLAUDE.md](CLAUDE.md) para el contexto completo, las restricciones técnicas y las fases.

## Estado actual — Fase 1, paso 1.0

| | |
|---|---|
| Catálogo digitalizado | ✅ 8 categorías, 90 productos |
| Prototipo visual de la carta | ✅ navegable |
| Carta real (Next.js + Supabase) | ⬜ no empezada |
| Impresión WebUSB | ⬜ no probada |

## Qué hay acá

```
data/catalogo.json     El catálogo: categorías, productos, precios.
                       Fuente única de verdad. Se edita acá y la carta cambia.
data/DUDAS.md          Lo que falta confirmar con Miguel, en checklist.
docs/mockup/carta.html Prototipo navegable de la carta del cliente.
                       Un solo archivo, sin dependencias: se abre en cualquier navegador.
Fotos Carta/           Las 11 fotos de la carta física de las que salió todo.
```

## Ver el prototipo

Sin instalar nada: abrir `docs/mockup/carta.html` en el navegador.

Publicado: **https://oscarestudianteusa-dot.github.io/Pirulos/**

## Reglas importantes

- **Precios en pesos chilenos enteros.** Nunca decimales ni floats.
- **No inventar datos del negocio.** Si falta un precio o un dato, va a `data/DUDAS.md`,
  no al código.
- Todo el texto de la interfaz en español chileno.
