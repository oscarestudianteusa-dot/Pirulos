# Qué sacarle a Loyverse antes de retirarlo

Fecha: 27/10/2026. Pregunta de Pipo: *¿querés algún dato de Loyverse para lo que viene?*
Sí, cuatro cosas. Tres son gratis y sirven ya; la cuarta cuesta y es una decisión tuya.

**Lo que no quiero: datos de clientes.** Nombres, teléfonos, correos. No los necesitamos para
nada, son datos personales de gente que no pidió estar en nuestro sistema, y no tenerlos es la
forma más simple de no tener que cuidarlos.

---

## El límite que manda sobre todo esto

En el **plan gratis** de Loyverse:

- Los reportes de ventas muestran solo los **últimos 31 días**.
- **Exportar reportes de ventas no está disponible.** Se pueden mirar en pantalla, no descargar.

Para ver más atrás y poder exportar hace falta el add-on **Unlimited Sales History**
(≈ USD 5–7 al mes por local, con prueba gratis). Esto no lo decido yo.

---

## 1. 🟢 Modificadores — **lo que más me sirve hoy**

**Back office → Artículos → Modificadores.**

En la carta de papel no están escritos, y es un PENDIENTE abierto desde el principio
(`DUDAS.md`, A-15): *qué modificaciones pide la gente de verdad y cuáles tienen costo extra.*

Si Miguel los configuró en Loyverse, ahí está la respuesta **salida del uso real**, no de lo que
alguien se acuerde. Y de paso el precio de cada uno, que es el dato que me falta para que el
carrito sume bien.

Mandame una captura de la lista, o escribila a mano si son pocos.

## 2. 🟢 Lista de artículos con precios — **para contrastar**

**Back office → Artículos → Lista de artículos.** Esta sí se puede exportar en el plan gratis
(es el catálogo, no un reporte de ventas).

Para qué: contrastar contra `data/catalogo.json`, que salió de las fotos de la carta.

Dos razones concretas:

- **Los precios se confirmaron el 14/08/2026 y hoy es 27/10.** Dos meses y medio. Si Miguel subió
  algo en el medio, la carta digital saldría con precios viejos y le costaría plata en cada venta.
- Un error de transcripción mío entre 90 productos es perfectamente posible. Dos fuentes
  independientes lo cazan; una sola, no.

*(En `DUDAS.md` quedó anotado que no hacía falta contrastar. Eso fue antes de que pasaran dos
meses y medio, y antes de que el contraste fuera gratis.)*

## 3. 🟢 Ventas de los últimos 31 días — **mirar, aunque no se pueda exportar**

**Back office → Reportes → Ventas por artículo**, y **Reportes → Resumen de ventas**.

Aunque no se descarguen, en pantalla responden tres cosas que hoy son preguntas abiertas:

| Qué miro | Qué PENDIENTE cierra |
|---|---|
| Recibos por día | *Volumen aproximado de pedidos al día* |
| A qué hora se concentran | *Horario de atención*, y las horas muertas de la Fase 4 |
| Qué productos encabezan la lista | Los primeros datos de popularidad reales |

Con capturas de esas dos pantallas me alcanza. **El orden de los productos más vendidos es el dato
jugoso**: es la mitad de la matriz de menu engineering de la Fase 4 — la otra mitad son los costos,
que Loyverse no tiene.

## 4. 🟡 El historial completo — cuesta, y lo decidís vos

**Add-on Unlimited Sales History**, ≈ USD 5–7 al mes, con prueba gratis. Permite ver y **exportar**
todo el histórico.

**A favor de hacerlo, y hacerlo ahora:**

- La Fase 4 es el diferencial del proyecto: lo que Loyverse no hace. Con histórico puede dar
  recomendaciones **el primer día**. Sin histórico, hay que esperar meses a juntar datos propios.
- Nadie documenta cuánto tiempo guarda Loyverse los datos que no te deja ver. Si algún día esa
  cuenta se cierra o caduca, el histórico se va con ella y no hay vuelta atrás.
- A mí me sirve para diseñar: ver cómo son los datos de ventas reales es distinto a imaginarlos.
  El modelo de las Fases 3 y 4 sale mejor mirando datos que suponiendo.

**En contra:**

- Las Fases 2 en adelante son condicionales a que haya tiempo. Puede que nunca lleguemos ahí.
- Cuanto más tarde se exporte, más datos trae. Si la prueba gratis se usa una sola vez, usarla
  ahora significa no tener los meses que vienen.

**Mi recomendación: hacerlo igual, y ahora.** El argumento que me convence no es la Fase 4, es que
el dato puede desaparecer. Los meses que vienen los vamos a tener en **nuestra** base de datos de
todas formas, una vez que la Fase 1 esté andando. Lo que no vamos a poder recuperar nunca es lo que
ya pasó.

Si lo hacés: en el selector de fechas elegir desde el **primer día de actividad** hasta hoy, con
*todos los días*, *todas las tiendas* y *todos los empleados*, y exportar. El archivo va a
`data/loyverse/` — y ojo, ese export **no** debe traer datos de clientes.

---

## Orden sugerido

1. Los modificadores (10 minutos, y desbloquea la carta).
2. Las capturas de los dos reportes (5 minutos, cierra dos PENDIENTES).
3. El export de artículos (5 minutos, protege los precios).
4. Pensar lo del add-on sin apuro.

Nada de esto bloquea que yo empiece a construir. Lo único que de verdad frena la carta son los
modificadores, y eso también lo puede contestar Miguel de memoria.
