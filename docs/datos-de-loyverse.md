# Qué sacarle a Loyverse — paso a paso

Fecha: 27/10/2026. La cuenta de Pirulo's es **de pago**, así que los exports están disponibles y
el histórico completo también. Eso cambia bastante: se puede sacar todo de una vez.

---

## ⚠️ Antes de bajar nada: dónde van estos archivos

**Este repositorio es público.** GitHub Pages sirve la carta desde `/docs`, y cualquiera puede ver
lo que haya acá. Los exports de ventas dicen cuánto factura Miguel, a qué hora y qué día. Eso no
es información de la carta: es el negocio de otra persona.

Ya agregué `data/loyverse/` al `.gitignore`. **Los archivos van ahí y se quedan en el computador.**
Yo los leo en local sin problema; no necesitan estar en GitHub para que yo trabaje con ellos.

Creá la carpeta antes de empezar:

```bash
mkdir -p "data/loyverse"
```

**Dos reglas al bajarlos:**

1. **No los abras en Excel y los vuelvas a guardar.** Excel rompe los acentos de los CSV en UTF-8
   y a veces convierte números en fechas. Bajalos y dejalos tal cual. Si querés mirarlos, abrilos
   en Google Sheets, que no los toca.
2. **El export de clientes no lo quiero.** Nombres, teléfonos y correos de gente que no pidió estar
   en nuestro sistema. No lo necesitamos para nada, y no tenerlo es la forma más simple de no tener
   que cuidarlo.

---

## Cómo entrar al Back Office

**Con la tablet no alcanza.** La app del POS no exporta nada: los exports existen solo en el Back
Office web, y eso pide el correo y la contraseña de la cuenta de Loyverse, que es de Miguel.

Tres caminos, de mejor a peor:

**A · Que Miguel entre él.** Lo más simple y gratis. Se sienta un rato con el computador, entra a
https://loyverse.com/back-office, y hacen los cuatro exports juntos — son diez minutos. O los hace
él y te pasa los archivos. Sin contraseñas de por medio y sin instalar nada.

**B · Que Miguel te cree un usuario propio.** Es lo más prolijo: tenés tu propio acceso, con
permisos acotados, y él lo puede revocar cuando quiera. **Pero la gestión de empleados en Loyverse
es un add-on de pago**, con prueba gratis.

→ *Vale la pena revisar si ya lo tienen activo*: **Ajustes → Facturación y suscripciones**. Si la
cuenta ya paga ese add-on, esta es la opción buena. Si no, no lo contraten solo para esto: la A
hace lo mismo gratis.

Si lo activan: *Empleados → Lista de empleados → Añadir empleado*, con un rol que tenga
**«Acceso al Back Office»** y, dentro, **«Ver informes de ventas»** y **«Gestionar artículos»**.
Con eso me sobra, y Miguel no te da acceso a facturación ni a datos de clientes.

**C · Que te pase sus credenciales.** Funciona, pero le da acceso a todo: configuración,
facturación y los datos de sus clientes. Es decisión de él, no la recomiendo si la A es posible.

> **A mí no me mandes las credenciales.** No las necesito y no las quiero. Lo único que necesito
> son los CSV.

*Para saber de qué cuenta se trata: en la app de Loyverse de la tablet, el correo de la cuenta
aparece en el menú lateral. Eso le dice a Miguel cuál es, aunque no sirva para entrar.*

### Si conseguir el acceso se demora, esto no frena nada

Lo único que bloquea la carta son **los modificadores**, y eso **Miguel lo puede contestar
hablando**, en cinco minutos y sin entrar a ningún lado:

> *¿Qué cosas te piden que les saques o les agregues? ¿Cuáles cobras aparte y cuánto?*

Con esa respuesta arranco igual. El export de modificadores no es imprescindible: es mejor, porque
trae **cuántas veces pidieron cada uno** y con eso la carta los puede ordenar por uso real en vez
de por lo que uno se acuerde. Pero es una mejora, no un requisito.

---

# Los cuatro exports, en orden de importancia

Todo se hace desde el **Back Office**: https://loyverse.com/back-office (en el computador, no en
la app del teléfono).

**Filtros comunes a todos los reportes.** Donde diga de elegir período y filtros, poné siempre:

- **Fechas**: desde el **primer día de actividad** del local hasta **hoy**
- **Todo el día** (no una franja horaria)
- **Todas las tiendas**
- **Todos los empleados**

---

## 1 · Ventas por modificador 🔴 — *el que desbloquea la carta*

**Reportes → Ventas por modificador** → período y filtros de arriba → **Exportar**

Guardar como: `data/loyverse/ventas-por-modificador.csv`

**Por qué este primero.** Es el único dato de Loyverse que hoy frena la Fase 1. En la carta de
papel los modificadores no están escritos, y es un PENDIENTE abierto desde el principio
(`DUDAS.md`, A-15): *qué pide la gente de verdad y cuáles tienen costo extra.*

Este reporte no me dice solo cuáles existen: me dice **cuántas veces los pidieron**. O sea que
puedo ordenar la carta poniendo arriba los que la gente realmente usa, en vez de una lista larga
donde hay que buscar. Eso sale de datos de uso real, no de la memoria de nadie.

**Además, sacá una captura de pantalla de Artículos → Modificadores.** El reporte dice qué se
vendió; la pantalla de configuración dice **cuánto cuesta cada uno** y a qué productos aplica, que
es lo que necesito para que el carrito sume bien.

## 2 · Recibos por artículo 🔴 — *el más rico de todos*

**Reportes → Recibos** → período y filtros de arriba → **Exportar** → elegir **«Recibos por
artículo»** (no «Recibos» a secas)

Guardar como: `data/loyverse/recibos-por-articulo.csv`

**Ojo con la opción.** «Recibos» da una línea por boleta; **«Recibos por artículo» da una línea por
producto vendido**, con precio, descuentos e impuestos. Esa es la que quiero.

**Por qué es el mejor.** Es el dato crudo: cada línea de cada boleta con su hora. De ahí sale todo
lo demás sin tener que pedírtelo por separado — qué se vende más, a qué horas, qué días, el ticket
promedio, y **qué se pide junto con qué** (si el 70% de los churrascos se lleva papas, eso es una
promo que se arma sola).

Es la mitad de la matriz de menu engineering de la Fase 4. La otra mitad son los costos, que
Loyverse no tiene y hay que levantar con Miguel.

Si el archivo sale muy grande, bajalo por año y nombralos `recibos-por-articulo-2025.csv`, etc.

## 3 · Lista de artículos 🟠 — *para proteger los precios*

**Artículos → Lista de artículos** → botón **Exportar**

Guardar como: `data/loyverse/articulos.csv`

**Por qué.** Para contrastar contra `data/catalogo.json`, que salió de las fotos de la carta.

Dos razones concretas:

- **Los precios se confirmaron el 14/08/2026 y hoy es 27/10.** Dos meses y medio. Si Miguel subió
  algo en el medio, la carta digital saldría con precios viejos y le costaría plata en cada venta.
- Un error de transcripción mío entre 90 productos es perfectamente posible. Dos fuentes
  independientes lo cazan; una sola, no.

*(En `DUDAS.md` quedó anotado que no hacía falta contrastar contra Loyverse. Eso fue antes de que
pasaran dos meses y medio.)*

## 4 · Resumen de ventas 🟡 — *volumen y horarios*

**Reportes → Resumen de ventas** → período y filtros de arriba → **Exportar**

Guardar como: `data/loyverse/resumen-de-ventas.csv`

Cierra dos PENDIENTES del `CLAUDE.md` con datos en vez de estimaciones: **cuántos pedidos al día**
y **en qué horario trabaja el local de verdad** (que puede no ser el horario que está publicado).

El horario lo necesito para el indicador de abierto/cerrado de la carta. Si alguien entra a las
3 de la mañana, tiene que ver "cerrado" y no poder mandar un pedido que nadie va a leer.

---

# Opcional, para más adelante

**Ventas por tipo de pago** — *Reportes → Ventas por tipo de pago* → `tipos-de-pago.csv`

No lo necesito ahora, pero cuando llegue la Fase 2 (arqueo de caja) me dice qué proporción es
efectivo y qué proporción tarjeta. Si ya estás ahí, bajalo de paso: son dos clics.

**Ventas por categoría** — se deduce de los recibos, no hace falta.

---

# Resumen para llevar

| # | Dónde | Qué elegir | Archivo |
|---|---|---|---|
| 1 | Reportes → Ventas por modificador | Exportar | `ventas-por-modificador.csv` |
| 1b | Artículos → Modificadores | *captura de pantalla* | — |
| 2 | Reportes → Recibos | Exportar → **Recibos por artículo** | `recibos-por-articulo.csv` |
| 3 | Artículos → Lista de artículos | Exportar | `articulos.csv` |
| 4 | Reportes → Resumen de ventas | Exportar | `resumen-de-ventas.csv` |

Todos en `data/loyverse/`, todos con el rango completo de actividad, ninguno abierto y reguardado
en Excel. Cuando estén, avisame y los leo.

**Si solo tenés tiempo para uno**, que sea el **1**: es el único que bloquea la carta. El 2 es el
más valioso a largo plazo, pero puede esperar.
