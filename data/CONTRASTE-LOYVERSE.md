# Contraste: nuestro catálogo vs. Loyverse

Fecha: 27/10/2026. Fuente: export de **Lista de artículos** del Back Office
(`data/loyverse/articulos.csv`, fuera del repo), 187 artículos.

Nuestro `catalogo.json` salió de las fotos de la carta física. Este documento compara las dos
fuentes. **No cambié nada del catálogo todavía**: cada corrección de precio necesita que Pipo o
Miguel la confirmen, y varias de estas no son errores sino decisiones de alcance.

Resumen: **la carta física que fotografiamos no es todo lo que vende Pirulo's.** El catálogo no
está mal, está incompleto, y hay tres cosas que pueden costar plata.

---

# 🔴 1. Hay DOS tiendas, con precios distintos

La cuenta tiene **`Pirulos`** y **`Pirulos Foodtruck`**. De los 187 artículos, **133 tienen precio
distinto entre una y otra** — el foodtruck es sistemáticamente más barato.

```
As SOLO CARNE        local $3.600   foodtruck $3.000
5 vienesa + bebida   local $13.990  foodtruck $10.990
Agua mineral         local $800     foodtruck $600
Arrollado Primavera  local $1.000   foodtruck $600
```

Todo lo que comparé acá es contra la tienda **`Pirulos`** (el local), que es la que coincide con
las fotos de la carta.

**Esto choca con un no-objetivo del `CLAUDE.md`**: "Multi-local, multi-sucursal... Es un local, un
dueño". Resulta que no: son dos puntos de venta con listas de precios separadas.

**Decisión que hay que tomar:** ¿la carta digital es solo del local, o el foodtruck también la va
a usar? Si es solo el local, no cambia nada y seguimos igual. Si el foodtruck también, hay que
meter precio por tienda en el modelo de datos, y eso es trabajo que hoy no está contemplado.

→ **Mi recomendación: solo el local, por ahora.** La Fase 1 ya tiene alcance suficiente. Pero
conviene que el modelo de datos deje la puerta abierta, porque agregarlo después cuesta mucho más
que preverlo ahora.

# 🔴 2. El precio SÍ cambia según la proteína — en tres casos

En `DUDAS.md` quedó confirmado por Pipo: *"El precio del sándwich NO cambia según la proteína"*, y
de ahí salió modelar la proteína como **modificador obligatorio sin costo**.

Loyverse tiene una categoría por proteína, así que se puede verificar uno por uno. **De 21
sándwiches, 18 cuestan igual en las cuatro proteínas.** Tres no:

| Sándwich | Churrasco | Pollo | Hamburguesa | **Lomito** |
|---|---|---|---|---|
| Italiano | $4.600 | $4.600 | $4.600 | **$5.000** (+400) |
| Chacarero | $4.800 | $4.800 | $4.800 | **$5.700** (+900) |
| Ita/Luco | $5.000 | $5.000 | $5.000 | **$4.700** (−300) |

Las tres excepciones son de **Lomito**, lo que tiene sentido: el lomo es el corte más caro.

**Pero ojo, puede ser un error de Loyverse y no una regla.** "Lomito Chacarero" a $5.700 es
justo el precio de Chacarero 2.0 y de Pirulastico — huele a dedo equivocado al cargar el artículo.
Y Ita/Luco siendo $300 **más barato** en lomito no tiene lógica de costos.

**Hay que preguntarle a Miguel estas tres, una por una.** Si son reales, la proteína no puede ser
un modificador sin costo: tiene que poder sumar. Si son errores de Loyverse, seguimos como está.

→ **Mientras tanto no toco el catálogo.** Pero el modelo de datos sí va a soportar que un
modificador tenga precio: cuesta lo mismo preverlo y evita rehacer la carta entera después.

# 🔴 3. Los modificadores existen — pero no como modificadores

**La pantalla de Modificadores de Loyverse está vacía.** Miguel nunca usó esa función. Por eso el
reporte "Ventas por modificador" no tiene datos: no hay nada que reportar.

Los agregados los vende como **artículos sueltos, en una categoría llamada `Extras`**:

| Extra | Local | Foodtruck |
|---|---|---|
| 🥑 Palta | $1.000 | $600 |
| 🧀 Queso | $1.000 | $600 |
| 🍄 Champiñón | $1.000 | $300 |
| 🐖 Tocino | $1.000 | variable |
| Cheddar laminado | $1.000 | $1.000 |
| Cheddar líquido | $1.500 | $1.000 |
| Extra CARNE | $1.700 | $1.500 |
| Doble hamburguesa | $1.800 | variable |
| Vienesa Vegana | $800 | $500 |
| Ingrediente extra | variable | $300 |

**Esto responde el PENDIENTE A-15 de `DUDAS.md`** — qué se agrega y cuánto cuesta — con datos de
producción, no de memoria.

Lo que **no** responde: qué le *sacan* a los sándwiches (sin tomate, sin mayo). Eso no existe en
Loyverse porque nunca se cobró, y se dice de palabra. **Esa parte sigue siendo pregunta para
Miguel**, y es justamente la que nuestro sistema va a registrar por primera vez.

# 🟠 4. Falta producto en nuestro catálogo

En `DUDAS.md` quedó: *"✅ La carta está completa. Las 11 fotos cubren la carta entera. No faltan
páginas, postres, café ni lista de agregados."* **Eso resultó no ser exacto.**

- **Café $700 y Té $600.** Están en Loyverse, no están en nuestro catálogo ni en las fotos.
- **Dos sabores de arrollado** que no teníamos: *Choclo/Queso/Ciboulette x5* y *Jamón/Queso x5*,
  ambos $4.000. Nosotros solo teníamos Primavera.
- **Una cuarta promo**: *"3 TOMATE MAYO"* $5.000.
- **`H Tapa arterias` $7.500** y **`Cheese Burger` $6.500**. Nuestro catálogo tiene la categoría
  Hamburguesas con **2 productos**; Loyverse tiene **24**.
- **Las empanaditas y acompañamientos se venden sueltos además de por 5**: Emp queso $700 la
  unidad vs $3.000 las cinco, Nugget $300 vs $1.000 los cuatro, Aros $300 vs $1.000 los cuatro.
  Nuestro catálogo solo tiene los packs.

**La pregunta de fondo para Miguel:** ¿todo esto se vende de verdad hoy, o son artículos viejos
que quedaron en Loyverse? La carta digital debería mostrar lo que se vende, no todo lo que alguna
vez existió.

# 🟡 5. Hamburguesas: la carta de papel miente por omisión

Nuestro catálogo tiene 2 hamburguesas porque eso mostraba la foto. Loyverse tiene **24**: las
mismas 21 combinaciones que los demás sándwiches, más Cheese Burger y Tapa Arterias.

O sea: **se puede pedir cualquier sándwich en versión hamburguesa**, igual que en pollo o lomito.
Eso encaja con la duda A-14 que ya estaba abierta.

Si se confirma, la carta digital queda **mejor que la de papel**: el cliente ve que puede pedir
Chacarero de hamburguesa, cosa que hoy solo sabe quien pregunta.

# 🟢 6. Lo que calzó perfecto

No todo son problemas. Estas quedaron verificadas contra una segunda fuente:

- **Las 17 Vienesas**: precio por precio, las 17 coinciden exacto.
- **Las tres promos** que teníamos: $5.500, $22.000 y $13.990, las tres iguales.
- **Las 8 bebidas** que teníamos: todas iguales.
- **Los packs de acompañamientos**: Emp Queso x5 $3.000, Mechada x5 $4.000, Queso/Camarón x5
  $3.500, Pollo/Mandarín x5 $4.000, Carne/Mongoliana x5 $4.000, Arrollado x5 $4.000, Nuggets x4
  $1.000, Aros x4 $1.000, Alitas x5 $4.000, Palitos $3.000.
- **Papas**: chica $2.000, mediana $3.000, grande $5.000.

*(Las tres "diferencias" que detectó el primer contraste automático — Queso, Arrollado Primavera y
Nugget — eran falsas alarmas: comparaba nuestro pack de 5 contra la unidad suelta de Loyverse.)*

**El trabajo de digitalización desde las fotos estaba bien hecho.** Lo que no podía saber es lo
que no estaba fotografiado.

# ⚪ 7. Delivery existe y está tarifado

Categoría `DELIVERY`, 10 tramos por distancia: $1.500 de 0 a 700 m, $2.000 hasta 1.200 m, $2.500
hasta 1.700 m, $3.000 hasta 2.200 m, $3.500 hasta 2.700 m, $4.000 hasta 3.200 m, y sigue.

El `CLAUDE.md` lo tiene como no-objetivo ("Delivery con seguimiento, repartidores, rutas"), y para
la Fase 1 sigue estando bien afuera. Pero vale saber que **el delivery existe y ya tiene precios
definidos**, porque el día que alguien pida la carta por WhatsApp para delivery, la pregunta va a
aparecer sola.

---

# Lo que hay que preguntarle a Miguel

En orden de cuánta plata mueven:

1. **Lomito Italiano $5.000, Lomito Chacarero $5.700, Lomito Ita/Luco $4.700** — ¿son los precios
   de verdad, o están mal cargados en Loyverse?
2. **¿Qué se le saca a los sándwiches?** (sin tomate, sin mayo, sin cebolla). Lo que se agrega ya
   lo sé por la categoría Extras; lo que se quita no está en ningún lado.
3. **¿Se pueden pedir todos los sándwiches en hamburguesa?** Loyverse dice que sí.
4. **¿Café, té, los dos arrollados nuevos y la promo "3 Tomate Mayo" se venden hoy?**
5. **¿Las empanaditas sueltas se venden, o solo por cinco?**
6. **¿El foodtruck va a usar la carta digital?**

# Lo que hay que decidir con Pipo

- Si el modelo de datos contempla **precio por tienda** desde ahora (yo diría que sí: la columna
  cuesta nada hoy y mucho después).
- Si los **modificadores llevan precio** (yo diría que sí, por el punto 2).
- Qué hacer con los artículos de Loyverse que no están en la carta física: ¿entran a la carta
  digital o se quedan afuera?
