# CLAUDE.md — Proyecto Pirulo's

## 1. Qué es esto

Sistema de gestión para **Pirulo's**, local de comida rápida en Santiago, Chile. Dueño: **Miguel**. Desarrollador: **Pipo** (JQ Soluciones).

El sistema reemplaza progresivamente a **Loyverse POS**, que es lo que el local usa hoy, y agrega dos cosas que Loyverse no puede hacer:

1. **Pedidos por WhatsApp**: el cliente escribe al local, recibe un link a una carta digital, arma su pedido con modificaciones, y esa comanda se imprime automáticamente en la impresora del local.
2. **Analítica de costos y rentabilidad**: saber cuánto cuesta producir cada producto, qué margen deja, qué rota más y qué conviene impulsar. Decisiones con datos, no por intuición.

También sirve como carta con QR para clientes dentro del local.

## 2. Restricciones duras (verificadas, no negociables)

### Loyverse
- La API de Loyverse **no permite crear open tickets ni órdenes** que aparezcan en el POS o en el KDS. Confirmado en su documentación y foro oficial.
- Solo permite `POST /v1.0/receipts` para crear **recibos ya pagados**, con un solo tipo de pago.
- Los datos de venta vía API están limitados a los **últimos 31 días** sin el add-on de historial ilimitado (devuelve `402` si pides más antiguo).
- **Conclusión**: no se puede integrar el flujo de comandas con Loyverse. Loyverse queda como sistema paralelo durante la transición y se retira al final.

### Impresora
**Modelo confirmado: Xprinter XP-N160II, 80mm, USB + Bluetooth, negra.**

| Parámetro | Valor |
|---|---|
| Ancho de papel | 80mm (79.5 ±0.5) → **48 caracteres** por línea, fuente A |
| Resolución | 203 DPI |
| Velocidad | 160–200 mm/s |
| Protocolo | ESC/POS y OPOS nativos, sin driver |
| Corte | Automático (`GS V B 0`) |
| Tabla de caracteres | **WPC1252 (`ESC t 16`)**, y antes **obligatoriamente `FS .`**. Ver abajo. Verificado en papel el 27/10/2026 |
| Secuencia de inicio | `ESC @` · `FS .` · `ESC t 16` → `1B 40 · 1C 2E · 1B 74 10`. **El `FS .` no es opcional**: la impresora viene de fábrica en modo de doble byte (kanji / GB chino) y mientras ese modo esté activo ignora el `ESC t` — toma el byte de la `á` como inicio de un carácter chino y se come el byte siguiente (`Sándwich` salía `S爅dwich`). Con `FS .` las tres tablas funcionan |
| VendorId USB esperado | `0x0483` (STMicroelectronics) — **sin confirmar**: no aparece en fuentes oficiales de Xprinter, solo como ejemplo genérico en código de terceros. La página de prueba muestra el real. No filtrar por este valor. |
| Buffer de entrada | 96 KB |
| Extra disponible | Puerto RJ11 para cajón de dinero |

- **Se conecta por Bluetooth a la tablet** del local (confirmado por Pipo, 27/10/2026). Acepta también USB, que queda como respaldo.
- **Estrategia adoptada: Web Serial sobre Bluetooth RFCOMM (SPP).** Chrome lo soporta en Android **desde la versión 138**, sin flags. El navegador envía comandos ESC/POS crudos directo a la impresora. Sin app puente, sin drivers, sin licencias.
- ✅ **PROBADO EN LA IMPRESORA REAL el 27/10/2026**, en la Honor Pad X9 con Chrome 155:
  - La conexión por SPP funciona (el ticket imprime `Via: serial`).
  - Los 48 caracteres son exactos, el corte automático funciona, y negrita / alto doble / centrado / alineación a la derecha salen bien.
  - **La comanda se imprimió sola a los 20 segundos, sin que nadie tocara la tablet.** El requisito que decidía la Fase 1 está cumplido.
  - **Reconecta sola.** MagicOS mató Chrome en pleno uso; al reabrirlo, la página dijo «reconectada sola (Bluetooth SPP)» sin ningún gesto. El ciclo completo está probado: se cae Chrome → se reabre → reconecta → imprime sin que nadie toque nada.
  - **Tildes resueltas** con `FS .` + WPC1252. CP850 también pasó y queda como respaldo; PC437 solo sirve para minúsculas.
  - **Convive con Loyverse.** Imprimió sola con Loyverse abierto y funcionando. No hay que separar los sistemas por canal: el plan C (Loyverse en Bluetooth, nosotros por USB) queda archivado, no hizo falta.
  - **Con esto la Fase 0 está cerrada. No queda ningún bloqueador técnico.**
- **Codificación: WPC1252, con mapeo directo.** Del `0xA0` al `0xFF` Windows-1252 coincide carácter por carácter con Unicode, así que el byte **es** el codepoint y no hace falta tabla a mano. Se eligió sobre CP850 por eso: en la comanda no va solo el texto de la carta, va **el nombre que escribe el cliente y sus notas**, y con una tabla hecha a mano habría que prever cada letra que a alguien se le ocurra. El tramo `0x80–0x9F` (comillas tipográficas, guiones largos, puntos suspensivos — los que pega la gente desde el teclado del celular) sí lleva mapa. Lo que no entra, se imprime sin tilde antes que como símbolo raro.
- Requisitos que impone:
  - **HTTPS obligatorio** (lo cubre Vercel).
  - **Chrome en Android 138 o superior.** Firefox y Safari no implementan ninguna de estas APIs.
  - La impresora debe estar **emparejada antes en los ajustes de Bluetooth de Android**. El navegador usa lo ya emparejado, no empareja él.
  - El permiso al puerto lo otorga el usuario **una vez**, con un gesto explícito. Después `navigator.serial.getPorts()` lo recupera sin gesto: **eso es lo que permite imprimir solo.**
- **Plan B**: Web Bluetooth (BLE GATT), si resulta que la impresora es de doble modo y expone una característica escribible. Sin verificar.
- **Plan C si Loyverse bloquea el Bluetooth**: esta impresora acepta Bluetooth **y** USB. Loyverse se queda con el Bluetooth y nuestro sistema se va al cable, sin pelear por el mismo canal. Verificar que acepte ambos activos.
- **Plan D**: app puente con servidor HTTP local (`github.com/parzibyte/plugin-impresora-termica-bt-android`). Ojo: desde Chrome 142 las peticiones a la red local pasan por el permiso de Local Network Access.
- **Descartado: RawBT.** Se invoca con un link `rawbt:` y navegar a un esquema externo exige gesto del usuario, así que no sirve para imprimir solo.
- **La impresión es automática**, no manual: ver `docs/impresion.md`. La regla que lo hace posible es que el navegador pide gesto para *elegir* el dispositivo, no para *escribirle*.
- La tablet debe quedar **despierta y con la PWA adelante** (`navigator.wakeLock`): con la pantalla apagada Chrome frena los temporizadores y la conexión.
- ⚠️ **La tablet es una Honor Pad X9 con MagicOS 7.1, y MagicOS mata apps en segundo plano de forma agresiva.** Esto puede cortar la conexión Realtime y la impresión automática sin aviso. Hay que desactivarlo a mano, por app, en dos lugares: *Ajustes → Aplicaciones → Acceso especial → Optimización de batería → Chrome → No permitir*, y *Ajustes → Batería → Inicio de aplicaciones → Chrome → gestionar manualmente* con **Ejecutar en segundo plano** activado. Sin esto, el sistema funciona en la demo y falla en el local un martes a las 9 de la noche.
- **Implicancia de arquitectura**: la impresión ocurre en la tablet, no en el servidor. La tablet debe estar encendida, con Chrome abierto en la PWA y el permiso USB concedido. El sistema debe tolerar que no lo esté: cola de impresión persistida, reintento manual y alerta visible cuando un pedido no logró imprimirse.

### WhatsApp
- **NO usar** librerías no oficiales (Baileys, whatsapp-web.js). Riesgo real de baneo del número del negocio.
- **v1**: mensaje de bienvenida automático nativo de WhatsApp Business con el link a la carta. Cero código, cero costo, cero riesgo.
- WhatsApp Cloud API (Meta) solo se evalúa más adelante si se justifica.

### Pagos
- **No hay pago online.** El cliente pide y paga al retirar en el local. No implementar pasarelas.

## 3. No-objetivos

Explícitamente fuera de alcance:
- Multi-local, multi-sucursal, roles complejos. Es un local, un dueño, pocos empleados.
- Delivery con seguimiento, repartidores, rutas.
- Pagos online.
- App móvil nativa para clientes (la carta es web).
- Contabilidad formal / integración con SII (ver PENDIENTES).

## 4. Stack

- **Framework**: Next.js (App Router) + TypeScript
- **Estilos**: Tailwind CSS
- **Base de datos + auth + realtime**: Supabase (Postgres). Realtime es crítico: la tablet debe recibir pedidos nuevos al instante.
- **Deploy**: Vercel (free tier)
- **Panel de Miguel**: PWA instalable en la tablet, diseñada para touch y pantalla chica
- **Carta del cliente**: web pública, mobile-first, sin login
- **Impresión**: Web Serial sobre Bluetooth RFCOMM (SPP) desde la PWA directo a la impresora (Chrome Android 138+). Respaldos: BLE, USB.

Justificación de Supabase sobre alternativas: subscriptions realtime out of the box, Postgres real (importante para las consultas analíticas de la fase 4), y free tier suficiente para el volumen de un local chico.

## 5. Modelo de datos (borrador — refinar con Claude Code antes de migrar)

```
categorias          id, nombre, orden, activa
productos           id, categoria_id, nombre, descripcion, precio, imagen_url,
                    activo, disponible, orden
modificadores       id, nombre, tipo (agregar|quitar|opcion), precio_extra
producto_modificadores  producto_id, modificador_id, obligatorio, max_selecciones

insumos             id, nombre, unidad (g|ml|un), stock_actual, stock_minimo
compras             id, fecha, proveedor, total
compra_items        compra_id, insumo_id, cantidad, costo_unitario
recetas             producto_id, insumo_id, cantidad   -- costo teórico del producto

pedidos             id, origen (whatsapp|qr_local|mostrador), nombre_cliente,
                    telefono, estado, total, creado_en, notas
pedido_items        pedido_id, producto_id, cantidad, precio_unitario, notas
pedido_item_mods    pedido_item_id, modificador_id

ventas              id, pedido_id, metodo_pago, total, turno_id, creado_en
turnos              id, apertura, cierre, monto_inicial, monto_final, diferencia

impresiones         id, pedido_id, estado (pendiente|impresa|fallida),
                    intentos, ultimo_error
```

Notas de diseño:
- `precio_unitario` se guarda **en el pedido**, no se lee del producto. Si Miguel sube precios, los pedidos históricos no deben cambiar.
- La tabla `impresiones` existe porque la impresión puede fallar. Nunca asumir que imprimió.
- Todos los montos en **pesos chilenos, enteros**. Sin decimales, sin floats. Usar `integer`.

## 6. Fases

Cada fase entrega algo que Miguel usa el mismo día. No se avanza a la siguiente sin que la anterior esté en producción y probada en el local.

**Decisión de alcance**: las Fases 0 y 1 son el proyecto comprometido. Las Fases 2 en adelante (el POS que reemplaza a Loyverse) se abordan **solo si hay tiempo**, considerando que Pipo está en semestre activo. El sistema debe quedar funcionando y útil aunque el proyecto se detenga al terminar la Fase 1. Nada de la Fase 1 debe requerir que las fases siguientes existan.

### Fase 0 — Reconocimiento ✅ **CERRADA el 27/10/2026**
- Confirmar todos los PENDIENTES de la sección 8.
- Fotografiar/anotar la carta completa: productos, precios, modificadores reales que la gente pide.
- **Prueba de impresión**: página mínima que se conecte a la impresora Bluetooth desde Chrome en la tablet, saque un ticket de prueba y **demuestre que puede imprimir sin que nadie toque la tablet**. **Si esto no funciona, todo lo demás no sirve.** Es el primer entregable técnico y bloquea todo lo demás. → `docs/prueba-impresion.html`, instrucciones en `docs/impresion.md`.

### Fase 1 — Carta digital + comanda impresa

**Insumo de partida**: ~15 fotos de la carta física de Pirulo's, en `/carta-fotos/`. De ahí sale el catálogo. No inventar productos ni precios que no estén en las fotos.

**Paso 1.0 — Digitalizar el catálogo (antes de cualquier código)**
- Leer todas las fotos y extraer a `data/catalogo.json`: categorías, productos, descripciones, precios.
- Todo precio en pesos chilenos, entero, sin puntos ni símbolos: `12990`, no `"$12.990"`.
- Generar en paralelo `data/DUDAS.md` con: texto ilegible, precios que no se distinguen, productos ambiguos, y todo lo que requiera confirmación de Pipo o Miguel.
- **Pipo valida el JSON antes de continuar.** Un precio mal transcrito le cuesta plata a Miguel en cada venta.

**Paso 1.1 — Carta pública**
- Mobile-first, sin login. El cliente entra desde el link de WhatsApp o el QR de la mesa.
- Categorías navegables, productos con precio y descripción.
- Modificadores por producto (sin tomate, extra queso, etc.).
- Carrito con edición: cambiar cantidad, quitar items, notas por producto.
- Campo de nombre del cliente (obligatorio) y nota general del pedido.
- Indicador de local abierto/cerrado según horario.

**Paso 1.2 — Recepción y comanda**
- El pedido se guarda en Supabase con estado `pendiente`.
- Pantalla de la tablet (PWA, Chrome): lista de pedidos entrantes vía realtime, con alerta sonora.
- **Impresión automática** de la comanda al llegar el pedido, sin que nadie apriete nada (requisito de Miguel, confirmado 27/10/2026). Sale por Bluetooth SPP. La PWA recupera el permiso del puerto con `getPorts()` al abrir, así que imprime sola también después de un reinicio de la tablet.
- Cola de impresión persistida: si falla, el pedido queda visible con botón de reimprimir. **Nunca perder un pedido en silencio.**

**Paso 1.3 — Distribución**
- QR impreso para las mesas apuntando a la carta.
- Link en el mensaje de bienvenida automático de WhatsApp Business.

**Formato de la comanda impresa** (48 caracteres de ancho):
```
PIRULO'S
COMANDA #0042
14/08/2026 21:35
------------------------------------------------
CLIENTE: Juan Pérez
------------------------------------------------
2x Churrasco Italiano             $ 11.980
   - sin tomate
1x Papas Fritas Grandes           $  4.500
   - extra cheddar                $    800
------------------------------------------------
TOTAL                             $ 17.280
NOTA: pasa a buscar en 20 min
------------------------------------------------
```
El diseño exacto se ajusta con Miguel después de ver el primer ticket real.

**Valor entregado**: los pedidos por WhatsApp dejan de escribirse a mano.

---

*Las fases siguientes son condicionales a disponibilidad de tiempo. No comprometerlas con Miguel como fecha.*

### Fase 2 — POS en tablet (condicional)
- Registrar ventas de mostrador desde la misma app.
- Estados del pedido (pendiente → en preparación → listo → entregado).
- Apertura y cierre de turno con arqueo de caja.
- Reporte diario de ventas.

**Valor entregado**: Miguel puede dejar de abrir Loyverse para vender.

### Fase 3 — Insumos, recetas y costos
- Registro de compras de insumos y su costo.
- Receta por producto (qué insumos y cuánto).
- Costo teórico por producto, calculado y actualizado con cada compra.
- Descuento automático de stock al vender.
- Alertas de stock mínimo.

**Valor entregado**: Miguel sabe cuánto le cuesta cada producto de verdad.

### Fase 4 — Analítica y asesoría
- Margen por producto (precio − costo).
- **Menu engineering**: clasificar cada producto en la matriz popularidad × margen:
  - Estrella (alta popularidad, alto margen) → proteger y destacar en la carta
  - Vaca / caballo de batalla (alta popularidad, bajo margen) → subir precio o bajar costo
  - Puzzle / enigma (baja popularidad, alto margen) → impulsar, reubicar en la carta
  - Perro (baja popularidad, bajo margen) → sacar de la carta
- Ventas por hora, día y producto. Detectar horas muertas.
- Varianza de costo teórico vs. consumo real (detecta merma o robo).
- Recomendaciones accionables en lenguaje simple, no solo gráficos.

**Valor entregado**: esto es lo que Loyverse no hace. Es el diferencial del proyecto.

### Fase 5 — Retiro de Loyverse
- Verificar paridad de funciones.
- Exportar histórico de Loyverse (ojo con el límite de 31 días).
- Período de operación en paralelo antes de cortar.

## 7. Reglas de trabajo para Claude Code

1. **No inventar datos del negocio.** Precios, productos, costos y nombres solo se escriben en el código si Pipo los confirmó. Si falta un dato, marcarlo como `// PENDIENTE DE DECIDIR` y preguntar. Jamás poner un valor "de ejemplo" que después parezca real.
2. **Explicar antes de codear.** Pipo está aprendiendo. Antes de implementar algo no trivial, explicar por qué se hace así y qué alternativas se descartaron. No saltarse pasos.
3. **Commits chicos y frecuentes**, con mensajes descriptivos en español.
4. **Nada de sobre-ingeniería.** Es un local chico. No microservicios, no abstracciones prematuras, no capas que nadie va a necesitar.
5. **Todo el texto de la interfaz en español chileno**, natural, no traducido.
6. **Los cálculos de dinero llevan tests.** El costeo de recetas y los totales de pedido son la parte donde un bug le cuesta plata a Miguel.
7. **Mobile-first en serio.** La carta se ve en celulares gama baja con datos móviles lentos. Optimizar imágenes agresivamente.
8. **La app de la tablet debe funcionar con internet inestable.** Cola local de acciones pendientes, sincronización al reconectar.
9. Al terminar cada fase, escribir en `/docs` cómo se usa lo construido, en lenguaje que Miguel entienda.

## 8. PENDIENTE DE DECIDIR

Confirmar con Miguel antes o durante la Fase 0:

- [x] ~~Marca y modelo de la impresora~~ → Xprinter XP-N160II, 80mm, USB+Bluetooth
- [x] ~~Confirmar que la tablet es Android~~ → **Honor Pad X9, modelo ELN-W09, Android 13 (MagicOS 7.1)**. Confirmado por Pipo, 27/10/2026.
- [x] ~~¿Qué versión de Chrome tiene la tablet?~~ → **Chrome 155.0.8059.81**. Pasa el mínimo de 138 que exige Web Serial sobre Bluetooth. **Bloqueador despejado.**
- [x] ~~¿Se conecta con adaptador OTG?~~ → la Pad X9 tiene USB-C con **modo host/OTG**, así que el respaldo por cable es posible con un adaptador USB-C a USB-A. Ojo: Honor avisa que al conectar un periférico la tablet puede pasar a carga inversa.
- [x] ~~¿Loyverse suelta el Bluetooth de la impresora?~~ → **Sí, conviven.** Imprimió sola con Loyverse abierto, 27/10/2026.
- [x] ~~¿Qué tabla de caracteres imprime bien las tildes y la ñ?~~ → **WPC1252**, con `FS .` antes. CP850 también sirve. Verificado en papel el 27/10/2026.
- [x] ~~¿El Bluetooth de la impresora es SPP clásico o BLE?~~ → **SPP**, por Web Serial. Es el camino bueno.
- [ ] ¿Hay WiFi estable en el local?
- [ ] ¿Cuántos productos tiene la carta? ¿Hay variantes (tamaños, combos)?
- [ ] ¿Qué modificaciones pide la gente realmente? (sin tomate, extra queso, etc.)
- [ ] ¿Cuántas personas atienden? ¿Necesita usuarios separados o basta con uno?
- [ ] **¿Miguel emite boleta electrónica?** ¿Con qué sistema? Esto puede ser bloqueante para retirar Loyverse.
- [ ] ¿Miguel tiene los costos de sus insumos, o hay que levantarlos desde cero?
- [ ] ¿El local tiene número de WhatsApp Business o WhatsApp normal?
- [ ] ¿Horario de atención? (para mostrar "cerrado" en la carta)
- [ ] ¿Hay dominio comprado? ¿Quién paga hosting?
- [ ] Volumen aproximado de pedidos al día.

## 9. Contexto de negocio

Este es un proyecto para el hermano de Pipo, no un cliente pagado como La Ruta del Forastero. Eso significa más libertad para experimentar, pero también riesgo de que nunca se termine por falta de presión externa. **Definir fechas para cada fase y tratarlas como compromisos reales.**
