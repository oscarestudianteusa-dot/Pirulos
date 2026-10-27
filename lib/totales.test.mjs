/* Tests de los cálculos de plata.
 *
 * Regla 6 del CLAUDE.md: "Los cálculos de dinero llevan tests. Es la parte
 * donde un bug le cuesta plata a Miguel."
 *
 * Correr con:  node --test lib/
 *
 * Los precios que aparecen acá son los reales de data/catalogo.json y los
 * agregados reales que salieron de Loyverse. Si alguien cambia un precio en
 * el catálogo, estos tests NO deberían romperse: prueban la aritmética, no
 * el catálogo. Pero sirven de ejemplo verificable de la carta real.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { precioUnitario, subtotalItem, totalPedido, pesos } from './totales.mjs';

const SANDWICH_ITALIANO = 4600;   // data/catalogo.json
const PAPAS_GRANDE      = 5000;
const MECHADA_QUESO     = 4000;
const PALTA             = 1000;   // Extras de Loyverse
const CHEDDAR_LIQUIDO   = 1500;

const churrasco = { nombre: 'Churrasco', precio_extra: 0 };      // proteína, sin costo
const sinTomate = { nombre: 'Sin tomate', precio_extra: 0 };     // quitar, sin costo
const palta     = { nombre: 'Palta', precio_extra: PALTA };
const cheddar   = { nombre: 'Cheddar líquido', precio_extra: CHEDDAR_LIQUIDO };

test('un producto solo vale su precio', () => {
  assert.equal(precioUnitario({ precio: PAPAS_GRANDE, cantidad: 1 }), 5000);
});

test('la cantidad multiplica', () => {
  assert.equal(subtotalItem({ precio: SANDWICH_ITALIANO, cantidad: 3 }), 13800);
});

test('un modificador sin costo no mueve el precio', () => {
  const item = { precio: SANDWICH_ITALIANO, cantidad: 1,
                 modificadores: [churrasco, sinTomate] };
  assert.equal(precioUnitario(item), 4600);
});

test('los agregados suman al precio unitario', () => {
  const item = { precio: SANDWICH_ITALIANO, cantidad: 1, modificadores: [palta] };
  assert.equal(precioUnitario(item), 5600);
});

test('varios agregados se suman entre sí', () => {
  const item = { precio: SANDWICH_ITALIANO, cantidad: 1,
                 modificadores: [churrasco, palta, cheddar] };
  assert.equal(precioUnitario(item), 4600 + 1000 + 1500);
});

test('el agregado se cobra por cada unidad, no una sola vez', () => {
  // dos sándwiches con palta son dos paltas: es el error clásico de carrito
  const item = { precio: SANDWICH_ITALIANO, cantidad: 2, modificadores: [palta] };
  assert.equal(subtotalItem(item), (4600 + 1000) * 2);
  assert.equal(subtotalItem(item), 11200);
});

test('el total suma todas las líneas', () => {
  // es la comanda de ejemplo que ya salió impresa en papel
  const items = [
    { precio: SANDWICH_ITALIANO, cantidad: 2, modificadores: [churrasco, sinTomate] },
    { precio: PAPAS_GRANDE,      cantidad: 1 },
    { precio: MECHADA_QUESO,     cantidad: 1 }
  ];
  assert.equal(totalPedido(items), 18200);
});

test('un carrito vacío vale cero, no NaN', () => {
  assert.equal(totalPedido([]), 0);
  assert.equal(totalPedido(undefined), 0);
});

test('un item sin modificadores no explota', () => {
  assert.equal(precioUnitario({ precio: 2500, cantidad: 1 }), 2500);
});

test('todo resultado es entero: nunca aparecen centavos', () => {
  const items = [
    { precio: 1300, cantidad: 7, modificadores: [palta, cheddar] },
    { precio: 13990, cantidad: 3 }
  ];
  const total = totalPedido(items);
  assert.ok(Number.isInteger(total), 'el total tiene decimales: ' + total);
  assert.equal(total, (1300 + 1000 + 1500) * 7 + 13990 * 3);
});

test('el formato de pesos usa punto de miles y no lleva decimales', () => {
  assert.equal(pesos(18200), '$ 18.200');
  assert.equal(pesos(800), '$ 800');
  assert.equal(pesos(0), '$ 0');
  assert.equal(pesos(1234567), '$ 1.234.567');
});

test('el total de la promo más cara de la carta da lo que dice la carta', () => {
  assert.equal(totalPedido([{ precio: 22000, cantidad: 1 }]), 22000);
  assert.equal(pesos(22000), '$ 22.000');
});
