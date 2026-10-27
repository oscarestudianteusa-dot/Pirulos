# Hoja de ruta — sesión de prueba de impresión

Fecha: 27/10/2026 · Tablet y impresora en manos de Pipo, al lado del computador.

Esta es la hoja para **llenar mientras pruebas**. Lo de abajo está en orden: cada bloque depende
del anterior. Al final está lo que tengo que recibir de vuelta para poder seguir.

El *por qué* de cada cosa está en [impresion.md](impresion.md). Acá va solo el qué hacer.

---

# PARTE 1 — Antes de tocar la tablet (5 minutos, en el computador)

### ☐ 1.1 Instalar Node.js

No está instalado y la Fase 1 no arranca sin él. Hazlo ahora que estás en el PC, porque es lo
único que bloquea que yo empiece a escribir código de la carta.

- Bajar la versión **LTS** de https://nodejs.org
- Instalar con las opciones por defecto
- **Cerrar y volver a abrir Claude Code** (si no, no ve el `node` nuevo)

Verificación — pégame la salida de esto:

```bash
node --version && npm --version
```

Resultado: `______________________`

### ☐ 1.2 Dejar este archivo abierto

Lo vas llenando a medida que avanzas. Al final me pasas lo que anotaste.

---

# PARTE 2 — Preparar la tablet (10 minutos)

Este bloque es puro requisito. Si algo de acá falla, la prueba no corre y hay que resolverlo
primero.

### ☐ 2.1 Confirmar que la tablet es Android

Ajustes → Información del teléfono / Acerca de la tablet.

- Modelo: `______________________`
- Versión de Android: `______________________`

### ☐ 2.2 Revisar la versión de Chrome — **esto es lo que puede bloquear todo**

Abrir Chrome en la tablet → menú de los tres puntos → **Configuración** → **Acerca de Chrome**.

- Versión de Chrome: `______________________`

| Lo que dice | Qué significa |
|---|---|
| **138 o más** | ✅ Perfecto, sigue al 2.3 |
| Menos de 138 | ⚠️ Actualizar desde Play Store ahora, con WiFi. Después volver acá |
| No se puede actualizar más allá de 137 | 🔴 Pará y avísame. Cambia el plan: hay que irse a USB o a app puente |

### ☐ 2.3 Encender la impresora

- Enchufada a su **fuente de poder** (no alimentada por la tablet)
- Con papel y la tapa **bien cerrada** hasta que haga clic
- La luz de encendido fija, no parpadeando

### ☐ 2.4 Emparejar la impresora por Bluetooth **en Android**

Esto es obligatorio: el navegador **no empareja**, solo usa lo que Android ya tiene emparejado.

Ajustes → Bluetooth → Buscar dispositivos → elegir la impresora.

- Nombre con que aparece: `______________________`
- PIN que pidió (si pidió): `______________________` *(suele ser `0000` o `1234`)*
- ¿Quedó como **Emparejado / Vinculado**? `SÍ / NO`

### ☐ 2.5 Cerrar Loyverse del todo

Por ahora. Más adelante lo probamos abierto a propósito.

No basta con dejarlo atrás: menú de apps recientes → deslizarlo para cerrarlo.

---

# PARTE 3 — La prueba (15 minutos)

Abrir **en Chrome** de la tablet:

### 👉 https://oscarestudianteusa-dot.github.io/Pirulos/prueba-impresion.html

### ☐ 3.1 Leer la tabla de arriba antes de tocar nada

La página parte mostrando qué APIs tiene este Chrome. Copiá lo que dice:

| | |
|---|---|
| Web Serial (Bluetooth SPP) | `disponible / NO disponible` |
| Web Bluetooth (BLE) | `disponible / NO disponible` |
| WebUSB | `disponible / NO disponible` |
| Contexto seguro (https) | `disponible / NO disponible` |

Si *Web Serial* dice **NO disponible**, volvé al paso 2.2: es la versión de Chrome.

### ☐ 3.2 Conectar

Tocar el botón dorado **«Bluetooth (SPP) — recomendado»**.

Chrome abre una lista de puertos.

- ¿Apareció la impresora en la lista? `SÍ / NO`
- Nombre con que apareció: `______________________`
- Estado que quedó arriba: `______________________`

**Si la lista salió vacía**, no sigas con el 3.3. Hacé esto en orden:
1. Tocar **«Bluetooth (BLE)»** y elegir la impresora ahí. Aunque no imprima, la página va a listar
   sus servicios — y ese es un dato que ninguna fuente tiene claro para Xprinter. Copiame el log.
2. Anotar y avisarme. No hace falta que sigas solo.

### ☐ 3.3 Ticket de prueba

Tocar **«Ticket de prueba»**.

- ¿Salió papel? `SÍ / NO`
- ¿Salió el ticket **completo** (termina diciendo "el camino funciona")? `SÍ / NO`
- ¿**Cortó** el papel solo? `SÍ / NO`
- ¿La línea de números llega justo al borde sin cortarse ni sobrar? `SÍ / NO`

### ☐ 3.4 Tildes y ñ — **guardá este ticket**

Tocar **«Prueba de tildes y ñ»**. Imprime el mismo texto tres veces, con tres tablas distintas.

Mirá cuál de los tres bloques muestra bien `á é í ó ú ñ`:

| Bloque | ¿Se lee bien? |
|---|---|
| PC437 (ESC t 0) | `SÍ / NO / a medias` |
| CP850 (ESC t 2) | `SÍ / NO / a medias` |
| WPC1252 (ESC t 16) | `SÍ / NO / a medias` |

**Saca una foto de este ticket y mándamela.** Es el dato que define cómo se imprime toda la carta.

### ☐ 3.5 Comanda de ejemplo

Tocar **«Comanda de ejemplo»**.

- ¿Se lee cómoda desde lejos, como la leería la cocina? `SÍ / NO`
- ¿Los precios quedan alineados a la derecha? `SÍ / NO`
- Qué le cambiarías al formato: `______________________`

### ☐ 3.6 🔴 LA PRUEBA QUE IMPORTA — que imprima sola

Esta es la que decide si lo que pidió Miguel es posible.

1. Tocar **«Imprimir sola en 20 segundos»**
2. **Dejar la tablet en la mesa y no tocarla.** Ni mirarla de cerca, ni mantener el dedo apoyado.
   La pantalla puede quedar encendida, pero sin que la toques.
3. Esperar la cuenta regresiva.

- ¿Salió la comanda sin que tocaras nada? `SÍ / NO`
- Qué quedó escrito en grande en la pantalla: `______________________`

### ☐ 3.7 🔴 LA SEGUNDA QUE IMPORTA — el reinicio

1. **Recargar la página** (deslizar hacia abajo, o el botón de recargar)
2. Mirar el renglón **Estado** de arriba, sin tocar ningún botón

- ¿Qué dice? `______________________`
- ¿Dice «reconectada sola»? `SÍ / NO`
- ¿O te pidió elegir la impresora de nuevo? `SÍ / NO`

Si dijo «reconectada sola», tocá **«Imprimir sola en 20 segundos»** otra vez y soltá la tablet.
Si imprime, está probado el ciclo completo: reinicio → reconecta → imprime sin nadie.

- ¿Imprimió después de recargar? `SÍ / NO`

### ☐ 3.8 Pantalla encendida

Tocar **«Mantener la pantalla encendida»** y dejar la tablet quieta un par de minutos.

- ¿Se apagó la pantalla? `SÍ / NO`
- Qué dijo el log: `______________________`

### ☐ 3.9 Ahora sí, con Loyverse abierto

1. Abrir Loyverse y dejarlo funcionando
2. Volver a Chrome, a la página de prueba
3. Tocar **«Imprimir sola en 20 segundos»** y soltar la tablet

- ¿Imprimió con Loyverse abierto? `SÍ / NO`
- Si no, el error exacto: `______________________`
- ¿Loyverse siguió imprimiendo sus propios tickets? `SÍ / NO / no probado`

Esto decide si los dos sistemas pueden convivir o si hay que separarlos por canal.

### ☐ 3.10 Copiar el diagnóstico

Tocar **«Copiar diagnóstico»** y mandármelo. Si el botón no funciona, seleccionar a mano el texto
del recuadro negro.

Trae la versión de Chrome, las APIs, el puerto, los servicios BLE si los hubo, y cada error con su
mensaje exacto. **Es lo más útil de todo**: con eso puedo diagnosticar sin estar ahí.

---

# PARTE 4 — Lo que necesito para seguir, en orden

### 🔴 Bloquea todo — solo tú

1. **El resultado de la Parte 3.** Sobre todo 3.6 y 3.7. Hasta no saber si imprime sola, cualquier
   código que escriba puede ser al tarro.
2. **Node.js instalado** (paso 1.1).

### 🟠 Bloquea la Fase 1 — tú, cuando quieras

3. **Cuenta de Supabase** y un proyecto creado. Yo no puedo crearlo: necesita tu correo y tu
   contraseña, y eso no lo toco. Cuando lo tengas, lo que necesito es:
   - La **URL del proyecto** (`https://xxxxx.supabase.co`)
   - La **anon key** (la pública, la que va en el navegador)
   - ⚠️ La **service_role key NO me la pases por chat.** Esa va en un archivo `.env.local` que ya
     está en el `.gitignore`. Te digo dónde ponerla cuando toque.
4. **Decidir si la comanda sale en una copia o dos** (cocina y mostrador).

### 🟡 Bloquea publicar la carta — hay que preguntarle a Miguel

Están los 15 en [DUDAS.md](../data/DUDAS.md). Los que de verdad frenan:

5. **Los sabores de bebida**, formato por formato. Sin la lista no se puede armar la sección.
6. **Qué lleva la Gringa, la Suprema y la Suprema Italiana.** Tengo deducciones mías de las fotos,
   y deducciones mías no van al catálogo.
7. **Cuántas unidades son los Palitos de Mozzarella** de $3.000.
8. **Los modificadores reales**: qué pide la gente de verdad (sin tomate, extra queso, extra palta)
   y **cuáles cuestan plata**.
9. **El horario de atención**, para mostrar "cerrado" en la carta.
10. **El número de WhatsApp**: ¿es WhatsApp Business o normal? El mensaje de bienvenida automático
    solo existe en Business.

### ⚪ Después, sin apuro

11. Cuenta de Vercel (mientras tanto GitHub Pages sirve para mostrar).
12. ¿Hay dominio comprado? ¿Quién paga qué?
13. ¿Miguel emite boleta electrónica, y con qué sistema? Puede ser bloqueante para retirar Loyverse
    en la Fase 5, pero no antes.

---

# PARTE 5 — Lo que hago yo mientras

Sin depender de nada de arriba:

- Refinar el esquema de Supabase (el borrador de la sección 5 del `CLAUDE.md`) y escribir el SQL de
  migración. Es diseño y SQL: no necesita Node ni la prueba.
- Escribir los tests de los cálculos de plata: totales de pedido con cantidades y modificadores.
  Regla 6 del `CLAUDE.md`, y es donde un bug le cuesta plata a Miguel.
- Dejar el script de carga que mete `data/catalogo.json` en Supabase.

Lo que **no** voy a empezar hasta tener el resultado de la Parte 3: el módulo de impresión de la
PWA. El transporte define cómo se escribe, y escribirlo dos veces es perder el tiempo.
