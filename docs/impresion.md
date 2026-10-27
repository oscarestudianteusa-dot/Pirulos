# Impresión de comandas — investigación, decisión y prueba

Actualizado: 27/10/2026 · Impresora: **Xprinter XP-N160II** (80 mm) · **conectada por Bluetooth**
· Tablet del local en mano.

Dos requisitos mandan sobre todo lo demás:

1. La impresora está **por Bluetooth**, no por cable.
2. La comanda tiene que **imprimirse sola** al llegar el pedido. Nadie aprieta un botón.

Este documento dice cómo se logra eso, qué se descartó y por qué, y deja lista la única cosa que
puede confirmarlo de verdad: una prueba en el fierro.

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
                                                    │  Chrome, abierta y   │
                                                    │  despierta           │
                                                    │                      │
                                                    │  · suena la alerta   │
                                                    │  · aparece el pedido │
                                                    │  · imprime SOLA      │
                                                    └──────────┬───────────┘
                                                               │ Bluetooth SPP
                                                               ▼
                                                        Xprinter XP-N160II
                                                          comanda + corte
                                                               │
                                                               ▼
                                                    Supabase: `impresiones`
                                                    estado = 'impresa'
```

**El punto que define toda la arquitectura: el servidor no imprime nunca.** Vercel no tiene cómo
hablarle por Bluetooth a una impresora que está en Santiago al lado de la tablet. La impresión
ocurre **dentro del navegador de la tablet**, que es el único que alcanza la impresora.

Consecuencia directa: si la tablet está apagada, sin Chrome o con la pantalla negra, el pedido
entra igual a Supabase pero **no se imprime**. De ahí salen dos reglas que no son opcionales:

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

## 2. Cómo se imprime sola (y por qué sí se puede)

Esta es la parte que suena imposible y no lo es. La regla de los navegadores es:

> Se necesita un gesto del usuario para **elegir** un dispositivo. No se necesita ningún gesto
> para **escribirle** después.

Así que el flujo real es:

- **Una sola vez**, al instalar: alguien toca "conectar impresora" y la elige de la lista. Ese
  permiso **queda guardado para el sitio**.
- **De ahí en adelante**, la PWA recupera la impresora sola (`navigator.serial.getPorts()`), abre
  el puerto y escribe cuando quiera. Un pedido que entra por Supabase Realtime dispara la
  impresión igual que un temporizador: sin tocar nada.

La página de prueba comprueba las dos mitades por separado: un botón que **imprime a los 20
segundos** mientras la tablet está suelta en la mesa (demuestra que escribir no necesita gesto), y
el estado al recargar, que tiene que decir **«reconectada sola»** (demuestra que el permiso
sobrevive a un reinicio).

### Lo que puede romper la impresión automática

| Riesgo | Mitigación |
|---|---|
| Android apaga la pantalla y Chrome frena los temporizadores y la conexión | **Wake Lock** (`navigator.wakeLock`) + tablet enchufada. La PWA lo pide al abrir; la página de prueba tiene el botón para comprobarlo |
| La PWA queda en segundo plano porque alguien abrió Loyverse | La pantalla `/pos` tiene que quedar adelante. Si Loyverse se usa en paralelo, esto es un problema operativo real: anotarlo en la prueba |
| Se reinicia la tablet | La cola vive en Supabase y la PWA la drena al abrir. Conviene dejar la PWA como app de inicio |
| La impresora se apaga o se sale del rango | La escritura falla, el pedido queda en rojo con botón de reimprimir, y suena la alerta de nuevo |
| Pedidos falsos: el link es público y no hay pago | Límite de pedidos por teléfono por hora y botón de anular en `/pos`. **Se imprime igual** — el valor del sistema es que nadie copie pedidos a mano |

---

## 3. Qué camino se usa para hablarle a la impresora

Con la impresora en Bluetooth, el orden quedó así:

| Camino | Veredicto | Por qué |
|---|---|---|
| **Web Serial sobre Bluetooth RFCOMM (SPP)** | ✅ **elegido** | Chrome lo soporta **en Android desde la versión 138**, sin flags (salió por el experimento `BluetoothRfcommAndroid`, habilitado para todos). Es justo el canal que usan las térmicas Bluetooth: SPP, UUID `00001101-…`. Sin app puente, sin driver, sin licencia. La impresora tiene que estar **emparejada antes** en los ajustes de Android: el navegador usa lo ya emparejado, no empareja él |
| **Web Bluetooth (BLE GATT)** | 🟡 se prueba igual | Web Bluetooth **solo** habla BLE. Si el Bluetooth de la impresora es clásico, no aparece por acá. Pero este modelo es de doble modo y nadie lo verificó, así que la prueba lista sus servicios y busca una característica escribible. Si existe, es una segunda vía sin app |
| **WebUSB** | 🟡 plan de respaldo | Ya está probado en código y funciona con impresoras de clase USB 7. Cuesta un cambio de cable en el local. Sigue siendo la opción más robusta si el Bluetooth da problemas |
| **App puente con HTTP local** ([parzibyte](https://github.com/parzibyte/plugin-impresora-termica-bt-android)) | 🟡 plan C | Un servidor HTTP en la tablet al que la PWA le hace `fetch`. Hoy tiene un costo nuevo: desde Chrome 142 (octubre 2025) las peticiones a la red local pasan por el permiso de **Local Network Access**, y en Chrome 147 eso alcanzó también a los WebSockets. Se puede, pero suma una app y un permiso más al camino crítico |
| **RawBT** (print service de Android) | ❌ **descartado por el requisito** | Se invoca con un link `rawbt:`, y navegar a un esquema externo necesita gesto del usuario. Sirve para imprimir apretando un botón; no sirve para imprimir **solo** |
| **Loyverse en Bluetooth, nosotros en USB** | 🟡 plan D | Esta impresora acepta los dos canales. Si las dos apps se pelean el Bluetooth, cada una se queda con el suyo. **Hay que verificar que acepte ambos activos** |
| **TCP al puerto 9100** | ❌ imposible | Una página web no puede abrir un socket crudo |
| **Imprimir desde el servidor** | ❌ imposible | Vercel no alcanza la impresora del local |

### Lo que la investigación **no** pudo confirmar, y por eso hay que probar

- **Si este Chrome y esta tablet tienen Web Serial sobre RFCOMM.** Necesita **Chrome 138 o
  superior**. La página muestra la versión y si la API existe.
- **Si el Bluetooth de la XP-N160II es clásico (SPP), BLE, o los dos.** Lo primero define el camino;
  lo segundo abriría una vía alternativa. Las fuentes de terceros no coinciden ni siquiera en el
  UUID de servicio BLE de Xprinter: una librería lo mapea a
  `E7810A71-73AE-499D-8C15-FAA9AEF0C3F2`, y en foros aparece el genérico `18F0` con característica
  `2AF1`. Por eso la prueba **no hardcodea** nada: lista todo lo que encuentra y usa la primera
  característica escribible.
- **Si el permiso del puerto Bluetooth sobrevive a recargar la página en Android.** En escritorio
  sí. En Android con un puerto Bluetooth está sin verificar, y es exactamente lo que decide si la
  tablet puede imprimir sola después de un reinicio. Chrome además no soporta del todo los eventos
  de conexión y desconexión sobre Bluetooth en Android, así que los fallos se detectan al abrir el
  puerto y al escribir, no escuchando eventos.
- **Qué tabla de caracteres imprime bien las tildes y la ñ.** La carta tiene Sándwich, Alemán,
  Dinámico, Camarón, Champiñón, Ají. Esto se decide mirando papel.
- **Si Loyverse suelta el Bluetooth.** Si lo toma en exclusiva, se va al plan D.

---

## 4. La prueba — qué hacer en la tablet

La página está en el repo y publicada por HTTPS, que es requisito de las tres APIs:

### 👉 https://oscarestudianteusa-dot.github.io/Pirulos/prueba-impresion.html

Es un archivo HTML suelto, sin librerías ni instalación.

### Antes de partir

- La impresora encendida, con papel y la tapa cerrada.
- **La impresora emparejada en Ajustes → Bluetooth de Android.** Sin esto no aparece en la lista.
- Abrir el link **en Chrome**. No en Samsung Internet, no en el navegador de WhatsApp, no en
  Firefox: ninguna de estas APIs existe ahí.

### Los pasos

1. Mirar la **tabla de arriba**. Dice qué APIs tiene este Chrome. Si *Web Serial* sale en rojo, hay
   que actualizar Chrome: hace falta la 138 o superior.
2. Tocar **Bluetooth (SPP)**. Chrome abre la lista de puertos.
   - Si la impresora aparece → elegirla.
   - **Si la lista sale vacía** → o no está emparejada en Android, o este Chrome es anterior al 138.
     Probar entonces el botón **Bluetooth (BLE)**: aunque no imprima, deja anotados los servicios
     que expone, que es justo el dato que falta.
3. Tocar **Ticket de prueba**. Tiene que salir completo y **cortar el papel**.
4. Tocar **Prueba de tildes y ñ**. Imprime el mismo texto tres veces, con PC437, CP850 y WPC1252.
   **Anotar cuál de las tres salió legible** — con ese dato se configura la app y se cierra uno de
   los PENDIENTES del `CLAUDE.md`.
5. Tocar **Comanda de ejemplo**. Es el formato real, con productos y precios de
   `data/catalogo.json`. Dice **COMANDA DE PRUEBA** en grande para que nadie la confunda.
6. **Tocar «Imprimir sola en 20 segundos» y soltar la tablet.** No tocarla hasta que salga el
   papel. Si sale, la impresión automática funciona y la Fase 1 es viable tal como la pediste.
7. **Recargar la página.** Si el estado dice **«reconectada sola»** sin tocar nada, la tablet va a
   poder imprimir después de un reinicio. Si pide elegir la impresora de nuevo, anotarlo: cambia
   cómo arranca la PWA.
8. Tocar **Mantener la pantalla encendida** y confirmar que no se apaga.
9. **Repetir los pasos 2 y 6 con Loyverse abierto y con Loyverse cerrado.** Esto decide si hace
   falta el plan D.
10. Tocar **Copiar diagnóstico** y mandarme ese texto. Trae la versión de Chrome, las APIs
    disponibles, el puerto, los servicios BLE si los hubo, y cada error con su mensaje exacto.

### Si algo falla, qué significa

| Lo que se ve | Qué pasa | Qué hacer |
|---|---|---|
| *Web Serial: NO disponible* | Chrome viejo o no es Chrome | Actualizar Chrome a 138 o más |
| *Contexto seguro: NO disponible* | Se abrió el archivo local en vez del link | Usar el link `https://` de arriba |
| La lista de puertos sale vacía | No está emparejada, o Chrome < 138 | Emparejar en Ajustes → Bluetooth y reintentar |
| `NetworkError` al abrir el puerto | La impresora está apagada o fuera de rango | Prenderla y acercar la tablet |
| `Access denied` / `in use` | Otra app tiene tomada la impresora | Cerrar Loyverse y cualquier print service (RawBT). Si solo falla con Loyverse abierto → **plan D** |
| Conecta pero no sale papel | Escritura aceptada, impresora sin imprimir | Revisar papel y tapa. Probar *Avanzar papel* |
| Sale media comanda y se corta | Se perdieron bytes en el camino | Está mandado en trozos de 512 bytes; si pasa, hay que bajarlos y agregar espera entre trozos |
| Sale basura en vez de texto | Tabla de caracteres equivocada | Es justo lo que mide el paso 4 |
| Imprime con el botón pero no a los 20 s | La pantalla se apagó y Chrome frenó el temporizador | Activar el Wake Lock del paso 8 y repetir |

**Si la prueba funciona**, la Fase 1 arranca con la parte riesgosa resuelta.
**Si no funciona**, se baja por la escalera: BLE → USB → app puente. Mejor saberlo ahora que
después de construir la carta.

---

## 5. Detalles técnicos que quedaron resueltos en la página

Esto ya está escrito y probado en `docs/prueba-impresion.html`; se reusa tal cual en la app.

- **Ancho**: 48 caracteres por línea en fuente A (80 mm, 203 DPI).
- **Comandos**: `ESC @` init, `ESC t n` tabla, `ESC a n` alineación, `ESC E n` negrita,
  `GS ! n` tamaño, `ESC d n` avance, `GS V B 0` corte parcial.
- **Un solo `enviar()` para los tres transportes.** El código que arma la comanda no sabe ni le
  importa si al final sale por Bluetooth o por cable. Cambiar de transporte no toca el ticket.
- **Trozos distintos por transporte**: 512 bytes en SPP, 100 en BLE (con 20 ms de espera), 4096 en
  USB. No es capricho: mandar todo de golpe por Bluetooth hace que la impresora pierda bytes y
  salga media comanda.
- **En Bluetooth el `baudRate` es decorativo** — RFCOMM no tiene velocidad de línea — pero la API
  lo exige igual.
- **Codificación**: la impresora no entiende UTF-8. Recibe **un byte por carácter** y lo interpreta
  según la tabla activa. Por eso hay un mapa de bytes por tabla para los caracteres que usa la
  carta, con una red de seguridad: lo que no está en la tabla se imprime **sin tilde** antes que
  como símbolo raro. Mejor "Sandwich" que "S?ndwich" en la comanda de la cocina.
- **Descubrimiento en vez de constantes**: en USB se recorren las interfaces buscando un endpoint
  *bulk OUT* prefiriendo clase 7; en BLE se recorren los servicios buscando la primera
  característica escribible. Hardcodear números de interfaz o UUIDs es lo que rompe estos
  proyectos al cambiar de modelo.
- **Nombres largos bajan de línea completos, no se cortan.** Cortarlos se come el final del nombre,
  que suele ser el dato que importa ("Papas Fritas **Grande**").

---

## 6. Lo que falta para codear la Fase 1

- **Instalar Node.js en el PC de desarrollo.** No está, y Next.js lo necesita.
- **Decidir si la comanda sale en una copia o dos** (cocina y mostrador).
- Del `CLAUDE.md`: versión de Android de la tablet, WiFi del local, y los modificadores reales que
  pide la gente.

Ya **no** está pendiente si imprime sola o con confirmación: imprime sola. Eso quedó decidido y es
lo que la prueba del paso 6 verifica.
