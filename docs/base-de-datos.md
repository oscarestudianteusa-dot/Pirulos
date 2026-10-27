# La base de datos — qué hay y por qué

27/10/2026 · Migración: `supabase/migrations/0001_esquema_inicial.sql`

Antes de que escribas código encima, acá está el razonamiento. Si algo de esto te parece mal,
mejor discutirlo ahora que después de construir la carta sobre eso.

---

## Las tablas

Nueve, y nada más:

```
categorias            la carta
productos
grupos_modificadores  las opciones (proteína, agregados, "sin...")
modificadores
producto_grupos       qué opciones aplican a qué producto

pedidos               lo que pide el cliente
pedido_items
pedido_item_mods

impresiones           la cola de la impresora
```

**No están** insumos, recetas, compras, ventas ni turnos, aunque el borrador del `CLAUDE.md` las
listaba. Esas son de las Fases 2 y 3. Una tabla que nadie usa igual hay que mantenerla, migrarla y
explicarla — y cuando por fin se ocupe, va a necesitar otra forma. Se crean cuando se usen.

---

## Las cinco decisiones que importan

### 1. El navegador no decide precios

Un pedido **no** se crea con un `insert`. Se crea llamando a la función `crear_pedido()`, que
recibe solo **qué** quiere el cliente —ids y cantidades— y saca los precios de la base.

Por qué: la carta corre con la clave anónima, que está a la vista de cualquiera que abra la consola
del navegador. Si el total viniera del cliente, se podrían pedir cuatro churrascos por $100. La
función además revisa que el producto esté activo y disponible, y que los agregados pedidos
**le correspondan a ese producto** y no a otro.

### 2. El pedido guarda copias, no solo referencias

Cada línea del pedido guarda el **nombre, la descripción, la categoría y el precio** del producto
tal como estaban al momento de pedirlo.

El `CLAUDE.md` ya lo pedía para el precio. Lo extendí al nombre por una razón concreta: la comanda
se puede **reimprimir**. Si Miguel corrige "Chararero" a "Chacarero" o saca un producto de la
carta, la comanda de hace tres meses tiene que salir del papel diciendo lo que decía. No es
historia abstracta: es lo que lee la cocina.

La referencia al producto se guarda igual, para la analítica de la Fase 4.

### 3. Los modificadores van agrupados — y acá me aparté del borrador

El borrador tenía `modificadores` + `producto_modificadores(obligatorio, max_selecciones)`. Esa
forma **no sabe decir lo que la carta necesita**: *"elegí exactamente una de estas cuatro
proteínas"*. Marcar cada proteína como obligatoria por separado significa "poné churrasco **y**
pollo **y** lomito".

Entonces las reglas viven en el grupo:

| Grupo | min | max | costo | opciones |
|---|---|---|---|---|
| Proteína | 1 | 1 | sin costo | churrasco · lomito · pollo · hamburguesa |
| Agregados | 0 | — | **con costo** | palta $1.000 · cheddar líquido $1.500 · extra carne $1.700… |
| Sin... | 0 | — | sin costo | sin tomate · sin mayo · sin cebolla |

No es sobre-ingeniería: sin el grupo, la regla "elegí una" habría que inventarla en el navegador,
que es justo donde no se puede hacer cumplir.

### 4. Anon crea pedidos pero no los lee

| | carta | pedidos |
|---|---|---|
| **anon** (el cliente) | leer | crear, solo vía `crear_pedido()` |
| **autenticado** (la tablet) | leer | todo |

Lo importante es el "no lee". Los pedidos traen **nombre y teléfono de clientes**. Si anon pudiera
leerlos, cualquiera con la clave pública —que está en el código de la página— se bajaría la lista
completa de clientes del local. Eso no se arregla después; se evita desde el principio.

→ **Consecuencia práctica: la tablet tiene que iniciar sesión.** Un usuario, el de Miguel. Lo
configuramos cuando armemos la PWA.

### 5. Toda comanda nace con su fila de impresión

Un trigger crea la fila en `impresiones` cada vez que entra un pedido. Que lo haga la base y no la
aplicación significa que **no existe forma de crear un pedido que se olvide de imprimirse**.

Y la cola vive en la base, no en el navegador. Ya vimos a MagicOS matarle Chrome a la tablet: si la
cola viviera en memoria, los pedidos de ese rato se perderían. Al abrir, la PWA pregunta por los
pendientes y los manda.

---

## Los cálculos de plata

Están en `lib/totales.mjs` con tests en `lib/totales.test.mjs`. Correr:

```bash
node --test lib/totales.test.mjs
```

12 tests, todos pasando. Prueban la aritmética, no el catálogo, así que cambiar un precio no los
rompe.

**Ojo con una cosa:** la cuenta está escrita dos veces — en SQL (la que vale) y en JavaScript (la
que el carrito muestra mientras el cliente arma el pedido). Es un riesgo conocido: si se separan,
el cliente ve un número y paga otro. Por eso la regla es de tres líneas y tiene tests. Si alguna
vez se complica —descuentos, promociones por combinación— hay que dejar de duplicarla y pedirle el
total al servidor en cada cambio.

El test que más vale es este: **un agregado se cobra por cada unidad, no una vez.** Dos sándwiches
con palta son dos paltas. Es el error clásico de carrito y le costaría plata a Miguel en cada
pedido doble.

---

## Cómo aplicarla

Cuando tengas el proyecto de Supabase creado:

1. Entrar al panel de Supabase → **SQL Editor**
2. Pegar el contenido de `supabase/migrations/0001_esquema_inicial.sql`
3. Ejecutar

Se puede correr completa de una vez. Si algo falla, no se aplica nada a medias.

Después hay que cargar los datos: las 8 categorías y los 90 productos de `data/catalogo.json`, más
los grupos de modificadores. Ese script lo escribo cuando tengas la URL y la clave del proyecto.

> **Las claves**: la URL y la `anon key` me las podés pasar por acá, son públicas por diseño. La
> `service_role` **no** — esa va a un `.env.local` que ya está en el `.gitignore`.

---

## Lo que falta decidir

- **Los "sin..."**: todavía no sabemos qué le saca la gente a los sándwiches. El grupo está
  modelado y vacío; se llena cuando Miguel conteste.
- **Hamburguesas**: si se confirma que todos los sándwiches van en hamburguesa, la proteína suma
  una opción más y no cambia nada del modelo. Si no, se queda con tres.
- **Anular pedidos**: el estado `anulado` existe. Falta decidir quién puede anular y si eso
  descuenta algo.
