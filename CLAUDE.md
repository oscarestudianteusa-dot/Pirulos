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
| Tabla de caracteres | PC437 por defecto; probar CP850 / WPC1252 para tildes y ñ |
| VendorId USB esperado | `0x0483` (STMicroelectronics) — **sin confirmar**: no aparece en fuentes oficiales de Xprinter, solo como ejemplo genérico en código de terceros. La página de prueba muestra el real. No filtrar por este valor. |
| Buffer de entrada | 96 KB |
| Extra disponible | Puerto RJ11 para cajón de dinero |

- Se conecta **por cable USB a la tablet** del local.
- Las Xprinter USB se presentan como **interfaz clase 7 (Printer)** estándar, que WebUSB sí puede reclamar. No está entre las clases protegidas del navegador.
- **Estrategia adoptada: WebUSB.** El navegador envía comandos ESC/POS crudos directo a la impresora. Sin app puente, sin drivers, sin licencias.
- Requisitos que impone WebUSB:
  - **HTTPS obligatorio** (lo cubre Vercel).
  - **Chrome en Android.** Firefox y Safari no implementan WebUSB. La PWA debe abrirse en Chrome, sí o sí.
  - El permiso al dispositivo lo otorga el usuario una vez, mediante un gesto explícito. No se puede pedir automáticamente al cargar la página.
- **Plan B si Loyverse bloquea el puerto USB**: esta impresora acepta USB **y** Bluetooth. Loyverse puede quedarse en Bluetooth y nuestro sistema en USB, sin pelear por la misma interfaz. Verificar que acepte ambos canales activos.
- **Plan C**: app puente con servidor HTTP local (`github.com/parzibyte/plugin-impresora-termica-bt-android`).
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
- **Impresión**: WebUSB desde la PWA directo a la impresora (Chrome Android)

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

### Fase 0 — Reconocimiento (sin código de aplicación)
- Confirmar todos los PENDIENTES de la sección 8.
- Fotografiar/anotar la carta completa: productos, precios, modificadores reales que la gente pide.
- **Prueba de impresión WebUSB**: página mínima que se conecte a la impresora desde Chrome en la tablet y saque un ticket de prueba. **Si esto no funciona, todo lo demás no sirve.** Es el primer entregable técnico y bloquea todo lo demás.

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
- Impresión automática de la comanda vía WebUSB al llegar el pedido.
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
- [ ] **Confirmar que la tablet es Android** y que tiene Chrome. Versión de Android.
- [ ] ¿La impresora se conecta con adaptador OTG o el puerto es directo?
- [ ] ¿Se puede probar WebUSB con Loyverse abierto, o hay que cerrarlo para liberar el USB?
- [ ] ¿Qué tabla de caracteres imprime bien las tildes y la ñ? (probar CP850, PC437, WPC1252)
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
