# Impresión de comandas — investigación, decisión y prueba

Fecha: 27/10/2026 · Impresora: **Xprinter XP-N160II** (80 mm, USB + Bluetooth) · Tablet del local en mano.

Este documento responde a una sola pregunta: **¿cómo llega un pedido de WhatsApp al papel?**
Y deja listo lo único que puede responderla de verdad, que es una prueba en el fierro.

---

## 1. El flujo completo, de punta a punta

```
  Cliente                    Internet                      Local
  ───────                    ────────                      ─────

  Escribe al                                            
  WhatsApp del   ──→  respuesta automática de
  local               WhatsApp Business con el link
                      (configuración manual, cero código)
       │
       ▼
  Abre la carta  ──→  carta web (Vercel)
  en el celular       arma el pedido
       │
       ▼
  Toca "Enviar"  ──→  Supabase: INSERT en `pedidos`
                      estado = 'pendiente'
                              │
                              │  Supabase Realtime
                              ▼
                                                    ┌──────────────────────┐
                                                    │  TABLET — PWA /pos   │
                                                    │  Chrome, siempre     │
                                                    │  abierta             │
                                                    │                      │
                                                    │  · suena la alerta   │
                                                    │  · aparece el pedido │
                                                    │  · arma los bytes    │
                                                    │    ESC/POS           │
                                                    └──────────┬───────────┘
                                                               │ WebUSB
                                                               ▼
                                                        Xprinter XP-N160II
                                                          comanda + corte
                                                               │
                                                               ▼
                                                    Supabase: `impresiones`
                                                    estado = 'impresa'
```

**El punto que define toda la arquitectura: el servidor no imprime nunca.** Vercel no tiene cómo
hablarle a una impresora USB que está en Santiago enchufada a una tablet. La impresión ocurre
**dentro del navegador de la tablet**, que es el único que tiene el cable.

Consecuencia directa: si la tablet está apagada, sin Chrome, o sin el permiso USB, el pedido entra
igual a Supabase pero **no se imprime**. De ahí salen dos reglas que no son opcionales:

1. **La cola de impresión vive en la base de datos, no en el navegador.** Al abrir la PWA, lo
   primero que hace es preguntar "¿hay pedidos sin imprimir?" y mandarlos. Si la cola viviera en
   memoria, un reinicio de la tablet se come los pedidos de ese rato.
2. **Nunca se asume que imprimió.** La tabla `impresiones` registra `pendiente | impresa | fallida`
   con `intentos` y `ultimo_error`. Si falla, el pedido queda arriba en la pantalla, en rojo, con
   botón de reimprimir. Un pedido perdido en silencio es peor que un pedido no impreso.

### Sobre "que pasen por el punto de venta"

El pedido pasa por **nuestro** punto de venta: la pantalla `/pos` de la tablet. No puede pasar por
Loyverse, y eso está cerrado desde antes: la API de Loyverse solo permite crear **recibos ya
pagados** (`POST /v1.0/receipts`), no órdenes ni tickets abiertos que aparezcan en su POS o en su
KDS. Loyverse no tiene por dónde recibir una comanda. Queda como sistema paralelo hasta la Fase 5.

---

## 2. Qué se evaluó para imprimir, y por qué quedó WebUSB

| Camino | Veredicto | Por qué |
|---|---|---|
| **WebUSB** desde Chrome Android | ✅ **elegido** | La impresora se presenta como clase USB 7 (*Printer*), que no está en la lista de clases protegidas del navegador. Android no trae driver de impresoras que se pelee por la interfaz — ese problema es de Windows, donde `usbprint` la toma en exclusiva. Sin app, sin driver, sin licencia. |
| **Web Bluetooth** | ❌ descartado | Web Bluetooth solo habla BLE/GATT. El Bluetooth de esta impresora es SPP clásico, que el navegador no expone. No es cosa de programarlo mejor: no hay API. |
| **Web Serial** | ❌ descartado | No existe en Chrome para Android. Solo escritorio. |
| **TCP directo al puerto 9100** | ❌ imposible | Una página web no puede abrir un socket TCP crudo. Da igual si la impresora tuviera red. |
| **Imprimir desde el servidor** | ❌ imposible | Vercel no alcanza una impresora USB en el local. Requeriría un agente corriendo en la tablet, que es justo lo que WebUSB evita. |
| **RawBT** (print service de Android) | 🟡 plan B | Se instala la app y la página la invoca con un link `rawbt:`. Funciona sin programar nada del lado Android, pero suma una app de terceros en el camino crítico y la documentación del esquema de URL está vieja. |
| **App puente con HTTP local** ([parzibyte](https://github.com/parzibyte/plugin-impresora-termica-bt-android)) | 🟡 plan C | Un servidor HTTP en la tablet al que la PWA le hace `fetch`. Más piezas, pero no depende de WebUSB. |
| **Bluetooth para Loyverse, USB para nosotros** | 🟡 plan D | Si resulta que las dos apps se pelean el USB: esta impresora acepta los dos canales. Loyverse se queda en Bluetooth y nosotros en USB. **Hay que verificar que acepte ambos activos.** |

### Lo que la investigación **no** pudo confirmar, y por eso hay que probar

- **El `vendorId` real de esta impresora.** El `0x0483` (STMicroelectronics) que estaba anotado en
  el `CLAUDE.md` no aparece en ninguna fuente oficial de Xprinter; donde sí aparece es como
  **ejemplo genérico** en código de terceros. La página de prueba lo muestra en pantalla, así que
  deja de ser una suposición. Por eso además la página **no filtra por vendorId**: filtra por clase
  de impresora, y tiene un segundo botón que muestra todos los dispositivos.
- **Qué interfaz y qué endpoint hay que reclamar.** Hay modelos que exponen más de una. La página
  los descubre y los lista; no hardcodea la interfaz 0.
- **Si Chrome en Android logra reclamar la interfaz con esta impresora.** No encontré ni un reporte
  público de alguien haciendo WebUSB + OTG contra una térmica en Android. Todo lo que hay es de
  escritorio. Esta es exactamente la razón por la que la Fase 0 existe y bloquea todo lo demás.
- **Qué tabla de caracteres imprime bien las tildes y la ñ.** La carta tiene Sándwich, Alemán,
  Dinámico, Camarón, Champiñón, Ají. Esto se decide mirando papel, no leyendo manuales.

---

## 3. La prueba — qué hacer en la tablet

La página está en el repo y publicada por HTTPS, que es requisito de WebUSB:

### 👉 https://oscarestudianteusa-dot.github.io/Pirulos/prueba-impresion.html

Es un archivo HTML suelto, sin librerías ni instalación.

### Antes de partir

- La impresora **enchufada a su fuente de poder** y encendida, con papel y la tapa cerrada.
- Cable USB de la impresora a la tablet. Si la tablet es USB-C y el cable es USB-A, va **adaptador
  OTG** en el medio.
- Abrir el link **en Chrome**. No en Samsung Internet, no en el navegador de WhatsApp, no en
  Firefox: WebUSB no existe ahí.

### Los pasos

1. Tocar **Conectar impresora**. Chrome abre la lista de dispositivos USB.
   - Si la impresora aparece → elegirla. Listo.
   - **Si la lista sale vacía** → tocar el segundo botón, *mostrar todos los dispositivos*. Que
     salga vacía con el filtro de clase impresora ya es un dato importante: significa que no se
     anuncia como clase 7.
2. Tocar **Ticket de prueba**. Tiene que salir el ticket completo y **cortar el papel**.
3. Tocar **Prueba de tildes y ñ**. Imprime el mismo texto tres veces, con PC437, CP850 y WPC1252.
   **Anotar cuál de las tres salió legible** — con ese dato se configura la app y se cierra uno de
   los PENDIENTES del `CLAUDE.md`.
4. Tocar **Comanda de ejemplo**. Es el formato real de comanda, con productos y precios de
   `data/catalogo.json`. Dice **COMANDA DE PRUEBA** en grande para que nadie la confunda con un
   pedido de verdad.
5. **Repetir con Loyverse abierto y con Loyverse cerrado.** Esto resuelve el PENDIENTE del conflicto
   por el puerto USB y decide si hace falta el plan D.
6. Tocar **Copiar diagnóstico** y mandarme ese texto. Trae el navegador, el `vendorId`, el
   `productId`, las interfaces, los endpoints y cada error con su mensaje exacto.

### Si algo falla, qué significa

| Lo que se ve | Qué pasa | Qué hacer |
|---|---|---|
| "Este navegador no tiene WebUSB" | No es Chrome | Abrir el link en Chrome |
| "La página no está en un contexto seguro" | Se abrió el archivo local en vez del link | Usar el link `https://` de arriba |
| La lista de dispositivos sale vacía | La tablet no ve la impresora | Revisar el OTG, el cable y que la impresora esté encendida con su fuente |
| `Access denied` / `SecurityError` | Otra app tiene tomada la interfaz | Cerrar Loyverse y cualquier print service (RawBT). Si solo falla con Loyverse abierto → **plan D** |
| `device busy` / `in use` | Interfaz ocupada | Desenchufar y enchufar el cable USB |
| Conecta pero no sale papel | Transferencia aceptada, impresora sin imprimir | Revisar papel y tapa. Si está todo bien, probar *Avanzar papel* |
| Sale basura en vez de texto | Tabla de caracteres equivocada | Es justo lo que mide la prueba 3 |

**Si la prueba funciona**, la Fase 1 arranca con la parte riesgosa ya resuelta.
**Si no funciona**, se va al plan B (RawBT) antes de escribir una línea de la carta. Eso es
precisamente para lo que sirve hacer esta prueba primero.

---

## 4. Detalles técnicos que quedaron resueltos en la página

Esto ya está escrito y probado en `docs/prueba-impresion.html`; se reusa tal cual en la app.

- **Ancho**: 48 caracteres por línea en fuente A (80 mm, 203 DPI).
- **Comandos**: `ESC @` init, `ESC t n` tabla, `ESC a n` alineación, `ESC E n` negrita,
  `GS ! n` tamaño, `ESC d n` avance, `GS V B 0` corte parcial.
- **Codificación**: la impresora no entiende UTF-8. Recibe **un byte por carácter** y lo interpreta
  según la tabla activa. Por eso hay un mapa de bytes por tabla para los caracteres que usa la
  carta, con una red de seguridad: lo que no está en la tabla se imprime **sin tilde** antes que
  como símbolo raro. Mejor "Sandwich" que "S?ndwich" en la comanda de la cocina.
- **Descubrimiento de interfaz**: se recorren las interfaces buscando un endpoint *bulk OUT*,
  prefiriendo las de clase 7, y se intenta `claimInterface` en cada una hasta que una acepte.
- **Envío en trozos de 4 KB**: los `transferOut` grandes fallan en algunos Android.
- **Nombres largos bajan de línea completos, no se cortan.** Cortarlos se come el final del nombre,
  que suele ser el dato que importa ("Papas Fritas **Grande**").
- **El permiso USB se concede una vez y queda guardado para el sitio.** Al reabrir la página, el
  dispositivo ya autorizado se reconecta solo. Esto es lo que hace viable que la tablet imprima sin
  que nadie toque nada después de un reinicio.

---

## 5. Decisiones pendientes antes de codear la Fase 1

Son de Pipo, no mías:

1. **¿La comanda se imprime sola al llegar el pedido, o el operador confirma primero?**
   Recomiendo **que se imprima sola** — el valor del sistema es justo que nadie tenga que copiar
   pedidos a mano. Pero el link de la carta es público y no hay pago, así que alguien puede mandar
   pedidos falsos y gastar papel. Mitigación simple: límite de pedidos por teléfono por hora, y
   botón de anular en la pantalla.
2. **¿Una copia o dos?** (cocina y mostrador).
3. **Dato que falta para programar**: en este PC **no hay Node.js instalado**, y la Fase 1 lo
   necesita para Next.js. Hay que instalarlo antes de empezar.

También siguen abiertos, del `CLAUDE.md`: versión de Android de la tablet, si hay WiFi estable en
el local, y los modificadores reales que pide la gente.
