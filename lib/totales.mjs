/* Cálculo de totales de un pedido.
 *
 * Esto existe por duplicado a propósito: la cuenta de verdad, la que vale,
 * la hace Postgres en `crear_pedido` (ver supabase/migrations). Esta copia
 * es para que el carrito pueda mostrar el total mientras el cliente arma el
 * pedido, sin ir al servidor en cada toque.
 *
 * Que sean dos implementaciones de la misma regla es un riesgo conocido: si
 * se separan, el cliente ve un número y paga otro. Por eso la regla está
 * escrita en un solo lugar acá, es de tres líneas, y tiene tests. Si alguna
 * vez se complica (descuentos, promociones por combinación), hay que dejar
 * de duplicarla y pedirle el total al servidor en cada cambio.
 *
 * Todos los montos son pesos chilenos ENTEROS. Nunca float: 0.1 + 0.2 no da
 * 0.3 en ningún lenguaje, y acá eso sería plata de Miguel.
 */

/** Lo que cuesta UNA unidad del item: el producto más sus agregados. */
export function precioUnitario(item) {
  const extras = (item.modificadores ?? [])
    .reduce((suma, m) => suma + (m.precio_extra ?? 0), 0);
  return item.precio + extras;
}

/** Lo que cuesta la línea completa del carrito. */
export function subtotalItem(item) {
  return precioUnitario(item) * item.cantidad;
}

/** El total del pedido. */
export function totalPedido(items) {
  return (items ?? []).reduce((suma, item) => suma + subtotalItem(item), 0);
}

/* Formato chileno: $ 18.200. Punto para los miles, sin decimales, sin
   centavos. `toLocaleString('es-CL')` ya lo hace bien, pero se envuelve acá
   para que el símbolo y el espacio sean iguales en la carta y en la comanda
   impresa — en el ticket el espacio importa, porque las columnas se alinean
   contando caracteres. */
export function pesos(monto) {
  return '$ ' + Math.round(monto).toLocaleString('es-CL');
}
