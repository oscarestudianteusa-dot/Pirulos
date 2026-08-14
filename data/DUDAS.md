# DUDAS — Digitalización de la carta (Fase 1, paso 1.0)

Fuente: 11 fotos en `Fotos Carta/` (01 a 11).
Digitalizado: 14/08/2026 · Respuestas de Pipo: 14/08/2026 (dos rondas).

Estado del catálogo: **8 categorías, 90 productos, precios confirmados vigentes.**
Lo que falta no impide construir la carta — son datos que solo Miguel tiene.

---

# A. PREGUNTAS PARA MIGUEL

*Checklist para llevar al local. Ninguna de estas bloquea el desarrollo, pero todas tienen que
estar respondidas antes de publicar la carta.*

### 🔴 Impiden publicar

- [ ] **1. Sabores de bebida.** Miguel maneja varios sabores, todos al mismo precio (confirmado
  por Pipo). Falta la **lista concreta**: ¿qué sabores hay en Personal 350cc, en Lata 350cc, en
  Desechable 1,5 lt y en Desechable 3 lt? ¿Son los mismos en los 4 formatos o cambian?
  → La carta **sí o sí** va a tener una sección para elegir sabor. Sin la lista no se puede armar.
  *(Ya anotado como requisito en `catalogo.json`.)*

- [ ] **2. ¿Qué lleva la Gringa?** No tiene descripción escrita en la carta, solo foto.
  En la foto se ve papas con cheddar, tocino y salsa barbecue — **pero eso es deducción mía, no lo
  escribí en el catálogo.**

- [ ] **3. ¿Qué lleva la Suprema?** Mismo caso. En la foto: papas con cheddar derretido y cebollín.

- [ ] **4. ¿Qué lleva la Suprema Italiana?** Mismo caso. En la foto: papas con carne, tomate
  picado, palta y mayo.

- [ ] **5. Palitos de Mozzarella $3.000: ¿cuántas unidades?** Es el único producto de
  Acompañamientos sin cantidad indicada. Pipo cree que son **4**, pero no está confirmado, así que
  el catálogo lo dejó **sin número**: dice solo "Palitos de Mozzarella".
  → Cuando se confirme, cambiar el `nombre` a "Palitos de Mozzarella (4 un)" en `catalogo.json`.

### 🟡 Afectan la comanda o la carta, no el precio

- [ ] **6. ¿El As tiene los 4 sándwiches extra?** Chacarero 2.0, Paltapeño, Pirulastico y Chemilico
  existen en Sándwich. Pipo confirmó que **no se hacen en pan de completo** (o sea, no van en
  Vienesas), pero el As no va en pan de completo, así que quedó la duda.
  → ¿El As los tiene? Si sí, **¿a qué precio cada uno?** Hoy el catálogo deja As con 17 productos.

- [ ] **7. ¿El Chemilico es siempre de churrasco?** Su descripción impresa dice
  "CHURRASCO - CEBOLLA CARAMELIZADA - HUEVO FRITO", dentro de una categoría donde el cliente elige
  la proteína. ¿Se puede pedir Chemilico de pollo o de lomito, o va fijo con churrasco?

- [ ] **8. "Papa Individual" (promo de $5.500): ¿es la Chica de $2.000?**
  Ya sabemos que "familiar" = grande. Falta el equivalente de "individual".

- [ ] **9. ¿La Chorrillana existe solo en tamaño grande ($15.000)?** Es el único producto de la
  carta sin versión mediana.

- [ ] **10. ¿"5 X" en empanaditas y arrollados significa 5 unidades?** Así lo interpreté y así se
  imprime en la comanda: "(5 un)".

- [ ] **11. ¿El agua individual es con gas, sin gas, o hay las dos?** ($800)

- [ ] **12. Nombres mal escritos en la carta impresa: ¿se corrigen o se dejan?**
  - "CHEESE BURGUER" → ¿"Cheese Burger"? *(hoy se deja tal cual está impreso)*
  - "LUCON" → ¿"Lucón"? *(hoy sin tilde, como la carta)*
  - "PIRULASTICO" → ¿"Pirulástico"? *(hoy sin tilde, como la carta)*
  - "CHARARERO" → **ya se corrigió a "Chacarero"**; confirmar que a Miguel le parece.

- [ ] **13. Descripciones de venta.** Papas, empanaditas, picoteo y bebidas no tienen ninguna
  descripción en la carta. No inventé ninguna. Si Miguel dicta dos líneas por producto, la carta
  digital vende bastante mejor que el papel.

- [ ] **14. ¿El As deja elegir la carne, como el Sándwich?** *(duda nueva, salió al armar el
  prototipo visual)*. La página de Sándwich dice "CHURRASCO-LOMITO-POLLO-HAMBURGUESA" en el
  encabezado; la de As no dice nada. Hoy el prototipo muestra el selector de carne **solo en
  Sándwich**. Si el As también se elige, hay que activarlo ahí.

- [ ] **15. Modificadores reales.** Pendiente completo, tal como dice el CLAUDE.md: qué pide la
  gente de verdad (sin tomate, extra queso, extra palta) y **cuáles tienen costo extra**.

---

# B. RESUELTAS

### ✅ La carta está completa
Las 11 fotos cubren la carta entera. No faltan páginas, postres, café ni lista de agregados.
*(Pipo, 2ª ronda.)*

### ✅ Los precios son los vigentes
Al 14/08/2026. No hace falta contrastar contra Loyverse.

### ✅ El precio del sándwich NO cambia según la proteína
Churrasco, lomito, pollo y hamburguesa valen lo mismo.
**Regla general que dio Pipo: si la carta no especifica otro precio, el precio es el mismo.**
→ La proteína se modela como **modificador obligatorio sin costo**, y **tiene que salir impresa en
la comanda** — la cocina necesita saber si es pollo o churrasco.

### ✅ Promo de $5.500
Es **Churrasco Italiano o Barros Luco + Papa Individual, con salsa incluida**.
La carta impresa solo decía "Churrasco Italiano + Papas Fritas".
→ Aplicado al nombre y descripción del producto. *(Queda abierto el tamaño exacto: pregunta A-8.)*

### ✅ Promo de $22.000
4 churrascos italianos **o** barros luco + bebida 3 lts + papa familiar.
**"Familiar" = tamaño Grande** ($5.000). → Aplicado a la descripción.

### ✅ AS y Vienesas están completas con 17 productos
Los 4 sándwiches extra (Chacarero 2.0, Paltapeño, Pirulastico, Chemilico) no se hacen en pan de
completo. *(Queda por confirmar el caso del As: pregunta A-6.)*

### ✅ Chacarero y Chacarero 2.0 son productos distintos
El 2.0 lleva agregados (queso y champiñón, según la carta). Ambos siguen separados.
Además se corrigió la escritura impresa "CHARARERO" → **"Chacarero"** en las tres categorías.

### ✅ La sección de hamburguesas se llama "Hamburguesas"
La foto 08 no tenía encabezado. Pipo la nombró al definir el orden de las categorías.

### ✅ "TOMAYE - MAYO" era un typo de "Tomate - mayo"
Repetido en las tres categorías (fotos 02, 05, 10). Corregido.

---

# C. ESTRUCTURA — decidida por Pipo

La carta digital queda con **8 categorías**, en este orden:

| # | Categoría | Productos |
|---|---|---|
| 1 | Promociones | 3 |
| 2 | Vienesas | 17 |
| 3 | As | 17 |
| 4 | Sándwich | 21 |
| 5 | Hamburguesas | 2 |
| 6 | Papas Fritas | 12 |
| 7 | Picoteo | 10 |
| 8 | Bebidas | 8 |

Agrupaciones respecto de la carta física:
- **Papas Fritas** absorbe las 6 secciones impresas: Papas Fritas, Gringa, Salchipapas, Suprema,
  Suprema Italiana y Chorrillana. El tamaño va en el nombre del producto ("Gringa Mediana").
- **Picoteo** absorbe las 4 secciones impresas: Empanaditas Medialuna, Empanaditas Triangular,
  Arrollados y Picoteo. Los productos se llaman por su sabor a secas ("Mechada Queso") y el
  formato baja a la descripción ("Empanadita triangular · 5 unidades"), que también se imprime
  en la comanda.
  *Nota de nombre*: la categoría se llamó "Acompañamientos" un rato, pero esa palabra de 15 letras
  no cabía en el cuadro de la portada sin achicar el título de las otras siete secciones. Se volvió
  a "Picoteo", que además es la palabra que usa la carta física.

---

# D. CRITERIOS DE TRANSCRIPCIÓN

Decisiones mías al pasar de la foto al JSON. Ninguna cambia un precio.

1. **Convertí TODO MAYÚSCULAS a Título/minúscula.** La carta está impresa en mayúsculas por
   diseño. Si Miguel las quiere así en la carta digital, se hace con CSS, no cambiando el dato.

2. **Agregué tildes que la carta impresa no tiene**: Alemán, Dinámico, Sándwich, Mandarín, Camarón,
   Orégano, Ají, Champiñón, Paltapeño.
   → Conecta con un PENDIENTE del CLAUDE.md: **hay que probar qué tabla de caracteres imprime bien
   tildes y ñ en la Xprinter** (PC437 / CP850 / WPC1252). Si ninguna funciona, la comanda se limpia
   de tildes **al imprimir**, no en el catálogo.

3. **Los tamaños quedaron dentro del nombre del producto**: "Papas Fritas Chica" en vez de
   categoría "Papas Fritas" + producto "Chica". Razón: en la comanda impresa "1x Chica" no le dice
   nada a la cocina.

4. **`descripcion: ""` en varios productos.** Papas, empanaditas, picoteo y bebidas no traen texto
   en la carta. **No inventé descripciones.** *(Ver pregunta A-13.)*

5. **IDs con prefijo de categoría** (`sandwich-italiano`, `as-italiano`, `vienesa-italiano`)
   porque los nombres se repiten entre las tres categorías de sándwich. Al migrar a Supabase la
   tabla tendrá su propio `id`; estos slugs sirven para la carga inicial y para poder re-ejecutarla
   sin duplicar productos.

6. **Sándwich / As / Vienesas repiten los mismos nombres.** Es correcto según la carta: cambia el
   precio, no el nombre. Implicancia práctica: si Miguel agrega un sándwich nuevo, hay que
   agregarlo en tres lados. Para la Fase 1 así queda; si más adelante molesta, se modela como
   "producto base + formato".

7. **En el carrito y en la comanda, el nombre lleva la categoría adelante.** Descubierto al
   dibujar el ticket: el primero decía "2x Italiano", pero *Italiano* existe en Sándwich ($4.600),
   As ($3.800) y Vienesas ($2.500). En la carta se distinguen porque están en secciones distintas;
   en el papel esa distinción se pierde y la cocina no sabe cuál armar.
   → Ahora imprime **"2x Sándwich Italiano"**, "1x As Italiano", "1x Vienesa Italiano".

8. **Los acompañamientos se llaman por su sabor, a secas** (decisión de Pipo, 14/08/2026).
   "Empanaditas Triangular Mechada Queso (5 un)" pasó a ser **"Mechada Queso"**. El formato y la
   cantidad se movieron a la descripción: *"Empanadita triangular · 5 unidades"*.
   Se aplicó a toda la categoría por consistencia: "Nugget Pollo" con descripción "4 unidades",
   etc. Los cinco sabores son únicos entre las dos masas, así que el nombre solo nunca es ambiguo.
   → En la comanda impresa, la descripción baja como sub-línea debajo del producto, porque la
   cocina necesita saber que son 5 y de qué masa:
   ```
   2x Mechada Queso                          $8.000
      Empanadita triangular · 5 unidades
   ```

9. **Los nombres largos bajan de línea en el ticket, no se cortan.** Cortarlos se comía el final
   del nombre, que suele ser el dato que importa.

10. **Aros de cebolla aparecen en dos lados**: dentro del Cheese Burguer y sueltos en
   Acompañamientos ($1.000 las 4). Anotado para la Fase 3 (recetas y costos).
