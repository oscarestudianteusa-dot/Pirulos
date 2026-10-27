-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  Pirulo's — esquema inicial (Fase 1)                                     ║
-- ║  27/10/2026                                                               ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
--
-- Alcance: SOLO lo que la Fase 1 necesita — carta, pedido, comanda impresa.
-- Las tablas de insumos, recetas, compras, ventas y turnos del borrador del
-- CLAUDE.md son de las Fases 2 y 3 y NO se crean todavía. Crear tablas que
-- nadie usa es deuda: hay que mantenerlas, migrarlas y explicarlas, y cuando
-- por fin se ocupen van a necesitar otra forma igual.
--
-- Reglas que atraviesan todo el archivo:
--   · Los montos son PESOS CHILENOS ENTEROS. `integer`, nunca numeric ni
--     float. $4.600 se guarda como 4600. Un float convierte "cuánto cobro"
--     en una pregunta con decimales de error.
--   · Nada que venga del navegador define un precio. Ver `crear_pedido`.
--   · Lo que se imprime en una comanda tiene que poder reimprimirse igual
--     dentro de un año, aunque el producto haya cambiado de nombre o ya no
--     exista. Por eso el pedido guarda copias, no solo referencias.

-- ───────────────────────────────────────────────────────────────────────────
-- 1. LA CARTA
-- ───────────────────────────────────────────────────────────────────────────

create table categorias (
  id          uuid primary key default gen_random_uuid(),
  slug        text not null unique,          -- 'sandwich', 'vienesas'
  nombre      text not null,
  orden       integer not null default 0,
  activa      boolean not null default true,
  creado_en   timestamptz not null default now()
);

comment on column categorias.slug is
  'Identificador estable que viene de data/catalogo.json. Permite re-ejecutar
   la carga inicial sin duplicar, y sobrevive a que Miguel renombre la
   categoría en pantalla.';

create table productos (
  id            uuid primary key default gen_random_uuid(),
  slug          text not null unique,        -- 'sandwich-italiano'
  categoria_id  uuid not null references categorias(id) on delete restrict,
  nombre        text not null,
  descripcion   text not null default '',
  precio        integer not null check (precio >= 0),
  imagen_url    text,
  activo        boolean not null default true,
  disponible    boolean not null default true,
  orden         integer not null default 0,
  creado_en     timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

comment on column productos.activo is
  'Si está en la carta o no. Apagarlo lo esconde para siempre, sin borrarlo:
   borrar un producto rompería los pedidos históricos que lo nombran.';
comment on column productos.disponible is
  'Si hoy se puede pedir. Esto es lo que Miguel apaga cuando se acaba algo a
   media tarde y vuelve a prender al día siguiente. Distinto de `activo`.';
comment on column productos.descripcion is
  'Baja como sub-línea en la comanda impresa. La cocina necesita leer
   "Empanadita triangular · 5 unidades" debajo del nombre.';

create index productos_categoria_idx on productos (categoria_id, orden);

-- ───────────────────────────────────────────────────────────────────────────
-- 2. MODIFICADORES
--
-- Acá me aparté del borrador del CLAUDE.md, y conviene explicar por qué.
--
-- El borrador tenía `modificadores` + `producto_modificadores(obligatorio,
-- max_selecciones)`. Esa forma no sabe expresar lo que la carta de Pirulo's
-- necesita de verdad: "elegí EXACTAMENTE UNA de estas cuatro proteínas".
-- Marcar cada proteína como obligatoria por separado diría "poné churrasco Y
-- pollo Y lomito", que es otra cosa.
--
-- Entonces los modificadores se agrupan, y las reglas (cuántos elegir, si es
-- obligatorio) viven en el GRUPO. Eso cubre los tres casos reales:
--
--   Proteína      min 1, max 1   · sin costo  · churrasco / lomito / pollo / hamburguesa
--   Agregados     min 0, max N   · CON costo  · palta $1.000, cheddar líquido $1.500…
--   Sin...        min 0, max N   · sin costo  · sin tomate, sin mayo, sin cebolla
--
-- No es sobre-ingeniería: sin el grupo, la regla "elegí una" no se puede
-- escribir, y la carta tendría que inventarla en el navegador — donde nadie
-- la puede hacer cumplir.
-- ───────────────────────────────────────────────────────────────────────────

create type tipo_grupo as enum ('opcion', 'agregar', 'quitar');

create table grupos_modificadores (
  id            uuid primary key default gen_random_uuid(),
  slug          text not null unique,        -- 'proteina', 'agregados', 'sin'
  nombre        text not null,               -- 'Elegí la carne'
  tipo          tipo_grupo not null,
  min_selecciones integer not null default 0 check (min_selecciones >= 0),
  max_selecciones integer check (max_selecciones is null or max_selecciones > 0),
  orden         integer not null default 0,
  creado_en     timestamptz not null default now(),
  constraint min_no_mayor_que_max
    check (max_selecciones is null or min_selecciones <= max_selecciones)
);

comment on column grupos_modificadores.max_selecciones is
  'null = sin tope. Para la proteína va min=1 y max=1.';

create table modificadores (
  id           uuid primary key default gen_random_uuid(),
  grupo_id     uuid not null references grupos_modificadores(id) on delete cascade,
  slug         text not null unique,
  nombre       text not null,
  precio_extra integer not null default 0 check (precio_extra >= 0),
  disponible   boolean not null default true,
  orden        integer not null default 0,
  creado_en    timestamptz not null default now()
);

comment on column modificadores.precio_extra is
  'Cero para la proteína y para los "sin". Los agregados sí cobran: la
   categoría Extras de Loyverse confirmó palta $1.000, cheddar líquido
   $1.500, extra carne $1.700. Que exista esta columna no obliga a usarla.';

create index modificadores_grupo_idx on modificadores (grupo_id, orden);

-- Qué grupos aplican a qué producto. Un sándwich lleva proteína, agregados y
-- "sin"; una bebida no lleva ninguno.
create table producto_grupos (
  producto_id uuid not null references productos(id) on delete cascade,
  grupo_id    uuid not null references grupos_modificadores(id) on delete cascade,
  orden       integer not null default 0,
  primary key (producto_id, grupo_id)
);

-- ───────────────────────────────────────────────────────────────────────────
-- 3. PEDIDOS
--
-- Acá está la regla que más importa de todo el archivo: **el pedido guarda
-- COPIAS, no solo referencias**.
--
-- El CLAUDE.md ya lo decía del precio ("si Miguel sube precios, los pedidos
-- históricos no deben cambiar"). Vale igual para el nombre: si renombra
-- "Chararero" a "Chacarero", o saca un producto de la carta, la comanda de
-- hace tres meses tiene que seguir diciendo lo que dijo cuando se imprimió.
-- Y como la comanda se puede reimprimir, esto no es solo historia: es lo que
-- sale en papel.
--
-- Por eso cada item guarda nombre, descripción y categoría del producto, y
-- cada modificador guarda su nombre y su precio. La referencia al producto
-- queda igual, para la analítica de la Fase 4.
-- ───────────────────────────────────────────────────────────────────────────

create type origen_pedido as enum ('whatsapp', 'qr_local', 'mostrador');
create type estado_pedido as enum
  ('pendiente', 'en_preparacion', 'listo', 'entregado', 'anulado');

comment on type estado_pedido is
  'La Fase 1 solo usa pendiente y anulado. Los otros tres son de la Fase 2
   (el POS). Están en el enum porque agregarlos después obliga a migrar el
   tipo, y escribirlos ahora no cuesta nada ni obliga a usarlos.';

create sequence comanda_numero_seq start 1;

create table pedidos (
  id             uuid primary key default gen_random_uuid(),
  numero         integer not null unique default nextval('comanda_numero_seq'),
  origen         origen_pedido not null,
  nombre_cliente text not null check (length(trim(nombre_cliente)) > 0),
  telefono       text,
  estado         estado_pedido not null default 'pendiente',
  total          integer not null check (total >= 0),
  notas          text not null default '',
  creado_en      timestamptz not null default now()
);

comment on column pedidos.numero is
  'El "COMANDA #0042" que lee la cocina. Corto y legible: un uuid en papel no
   le sirve a nadie para gritar un pedido.';
comment on column pedidos.total is
  'Calculado en el servidor por crear_pedido(), nunca recibido del navegador.';

create index pedidos_estado_idx on pedidos (estado, creado_en desc);

create table pedido_items (
  id            uuid primary key default gen_random_uuid(),
  pedido_id     uuid not null references pedidos(id) on delete cascade,
  producto_id   uuid references productos(id) on delete set null,
  -- copias congeladas al momento del pedido
  nombre        text not null,
  descripcion   text not null default '',
  categoria     text not null default '',
  cantidad      integer not null check (cantidad > 0),
  precio_unitario integer not null check (precio_unitario >= 0),
  notas         text not null default '',
  orden         integer not null default 0
);

comment on column pedido_items.categoria is
  'Se guarda porque la comanda la necesita adelante del nombre. "Italiano"
   existe en Sándwich ($4.600), As ($3.800) y Vienesas ($2.500): en la carta
   se distinguen por la sección, pero en el papel esa pista se pierde y la
   cocina no sabe cuál armar. Se imprime "2x Sándwich Italiano".';

create index pedido_items_pedido_idx on pedido_items (pedido_id, orden);

create table pedido_item_mods (
  id             uuid primary key default gen_random_uuid(),
  pedido_item_id uuid not null references pedido_items(id) on delete cascade,
  modificador_id uuid references modificadores(id) on delete set null,
  nombre         text not null,
  tipo           tipo_grupo not null,
  precio_extra   integer not null default 0 check (precio_extra >= 0),
  orden          integer not null default 0
);

comment on column pedido_item_mods.tipo is
  'Copiado del grupo para que la comanda sepa cómo imprimirlo sin más
   consultas: los "quitar" van con guión ("- sin tomate"), los demás con
   asterisco ("* Churrasco").';

create index pedido_item_mods_item_idx on pedido_item_mods (pedido_item_id, orden);

-- ───────────────────────────────────────────────────────────────────────────
-- 4. IMPRESIONES
--
-- Existe porque la impresión puede fallar y NUNCA hay que asumir que imprimió.
-- La cola vive acá, en la base, y no en el navegador de la tablet: si la
-- tablet se reinicia —y ya vimos a MagicOS matarle Chrome— los pedidos de ese
-- rato no se pueden perder. Al abrir, la PWA pregunta por los pendientes y
-- los manda.
-- ───────────────────────────────────────────────────────────────────────────

create type estado_impresion as enum ('pendiente', 'impresa', 'fallida');

create table impresiones (
  id            uuid primary key default gen_random_uuid(),
  pedido_id     uuid not null references pedidos(id) on delete cascade,
  estado        estado_impresion not null default 'pendiente',
  intentos      integer not null default 0 check (intentos >= 0),
  ultimo_error  text,
  creado_en     timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create index impresiones_pendientes_idx
  on impresiones (estado, creado_en) where estado <> 'impresa';

-- Toda comanda nace con su fila de impresión pendiente. Que lo haga un
-- trigger y no la aplicación significa que no hay forma de crear un pedido
-- que se olvide de imprimirse.
create function crear_impresion_pendiente() returns trigger
language plpgsql as $$
begin
  insert into impresiones (pedido_id) values (new.id);
  return new;
end;
$$;

create trigger pedidos_crean_impresion
  after insert on pedidos
  for each row execute function crear_impresion_pendiente();

-- ───────────────────────────────────────────────────────────────────────────
-- 5. CREAR UN PEDIDO
--
-- Esta función es la única puerta de entrada para los pedidos de la carta, y
-- existe por una razón de plata: **el navegador no puede decidir precios**.
--
-- Si la carta mandara el total, cualquiera con la consola abierta podría
-- pedir cuatro churrascos por $100. Acá el cliente manda solo QUÉ quiere
-- (ids y cantidades) y el precio sale de la base. También se valida que el
-- producto esté activo y disponible, y que los modificadores pertenezcan de
-- verdad a ese producto.
--
-- Corre como SECURITY DEFINER para poder leer precios y escribir el pedido
-- aunque quien llama sea anónimo y no tenga permiso de leer la tabla de
-- pedidos.
-- ───────────────────────────────────────────────────────────────────────────

create function crear_pedido(
  p_origen         origen_pedido,
  p_nombre_cliente text,
  p_telefono       text,
  p_notas          text,
  p_items          jsonb        -- [{producto_id, cantidad, notas, modificadores:[uuid]}]
) returns table (pedido_id uuid, numero integer, total integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pedido_id uuid;
  v_numero    integer;
  v_total     integer := 0;
  v_item      jsonb;
  v_prod      productos%rowtype;
  v_cat       text;
  v_item_id   uuid;
  v_cantidad  integer;
  v_subtotal  integer;
  v_mod_id    uuid;
  v_mod       record;
  v_orden     integer := 0;
  v_mod_orden integer;
begin
  if coalesce(trim(p_nombre_cliente), '') = '' then
    raise exception 'El pedido necesita un nombre de cliente';
  end if;
  if jsonb_array_length(p_items) = 0 then
    raise exception 'El pedido no tiene items';
  end if;

  insert into pedidos (origen, nombre_cliente, telefono, notas, total)
  values (p_origen, trim(p_nombre_cliente), nullif(trim(coalesce(p_telefono,'')), ''),
          coalesce(p_notas, ''), 0)
  returning id, pedidos.numero into v_pedido_id, v_numero;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select * into v_prod from productos
      where id = (v_item->>'producto_id')::uuid;

    if not found then
      raise exception 'Producto inexistente: %', v_item->>'producto_id';
    end if;
    if not v_prod.activo or not v_prod.disponible then
      raise exception 'El producto % no está disponible', v_prod.nombre;
    end if;

    v_cantidad := coalesce((v_item->>'cantidad')::integer, 0);
    if v_cantidad < 1 or v_cantidad > 50 then
      raise exception 'Cantidad inválida para %: %', v_prod.nombre, v_cantidad;
    end if;

    select nombre into v_cat from categorias where id = v_prod.categoria_id;

    v_orden := v_orden + 1;
    insert into pedido_items
      (pedido_id, producto_id, nombre, descripcion, categoria,
       cantidad, precio_unitario, notas, orden)
    values
      (v_pedido_id, v_prod.id, v_prod.nombre, v_prod.descripcion, coalesce(v_cat,''),
       v_cantidad, v_prod.precio, coalesce(v_item->>'notas',''), v_orden)
    returning id into v_item_id;

    -- El precio del item es el del producto más el de sus agregados. Todo
    -- eso por la cantidad: si pide 2 churrascos con palta, la palta va dos
    -- veces, porque son dos sándwiches con palta.
    v_subtotal := v_prod.precio;
    v_mod_orden := 0;

    for v_mod_id in
      select (jsonb_array_elements_text(coalesce(v_item->'modificadores','[]'::jsonb)))::uuid
    loop
      select m.id, m.nombre, m.precio_extra, m.disponible, g.tipo, g.id as grupo_id
        into v_mod
        from modificadores m
        join grupos_modificadores g on g.id = m.grupo_id
       where m.id = v_mod_id;

      if not found then
        raise exception 'Modificador inexistente: %', v_mod_id;
      end if;
      if not v_mod.disponible then
        raise exception 'El agregado % no está disponible', v_mod.nombre;
      end if;
      -- que el modificador le corresponda a ESTE producto, no a otro
      if not exists (select 1 from producto_grupos
                      where producto_id = v_prod.id and grupo_id = v_mod.grupo_id) then
        raise exception 'El agregado % no aplica a %', v_mod.nombre, v_prod.nombre;
      end if;

      v_mod_orden := v_mod_orden + 1;
      insert into pedido_item_mods
        (pedido_item_id, modificador_id, nombre, tipo, precio_extra, orden)
      values (v_item_id, v_mod.id, v_mod.nombre, v_mod.tipo, v_mod.precio_extra, v_mod_orden);

      v_subtotal := v_subtotal + v_mod.precio_extra;
    end loop;

    v_total := v_total + v_subtotal * v_cantidad;
  end loop;

  update pedidos set total = v_total where id = v_pedido_id;

  return query select v_pedido_id, v_numero, v_total;
end;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- 6. PERMISOS (RLS)
--
-- La carta es pública y corre con la clave anónima, que vive en el navegador
-- de cualquiera. Así que hay que ser explícito sobre qué puede hacer:
--
--   · LEER la carta  → sí. Es pública por definición.
--   · CREAR pedidos  → sí, pero solo por crear_pedido(), nunca con un insert
--                      directo, porque el insert directo deja elegir el total.
--   · LEER pedidos   → NO. Los pedidos traen nombre y teléfono de clientes.
--                      Si anon pudiera leerlos, cualquiera con la clave —que
--                      está a la vista en la página— se bajaría la lista
--                      completa de clientes del local.
--
-- La tablet entra autenticada y ahí sí lee todo.
-- ───────────────────────────────────────────────────────────────────────────

alter table categorias            enable row level security;
alter table productos             enable row level security;
alter table grupos_modificadores  enable row level security;
alter table modificadores         enable row level security;
alter table producto_grupos       enable row level security;
alter table pedidos               enable row level security;
alter table pedido_items          enable row level security;
alter table pedido_item_mods      enable row level security;
alter table impresiones           enable row level security;

-- La carta, para todos
create policy "la carta es pública" on categorias
  for select to anon, authenticated using (activa);
create policy "la carta es pública" on productos
  for select to anon, authenticated using (activo);
create policy "la carta es pública" on grupos_modificadores
  for select to anon, authenticated using (true);
create policy "la carta es pública" on modificadores
  for select to anon, authenticated using (true);
create policy "la carta es pública" on producto_grupos
  for select to anon, authenticated using (true);

-- Los pedidos, solo para la tablet
create policy "la tablet ve los pedidos" on pedidos
  for all to authenticated using (true) with check (true);
create policy "la tablet ve los items" on pedido_items
  for all to authenticated using (true) with check (true);
create policy "la tablet ve los mods" on pedido_item_mods
  for all to authenticated using (true) with check (true);
create policy "la tablet maneja las impresiones" on impresiones
  for all to authenticated using (true) with check (true);

-- Nadie anónimo escribe pedidos a mano: solo a través de la función.
revoke all on pedidos, pedido_items, pedido_item_mods, impresiones from anon;
grant execute on function crear_pedido(origen_pedido, text, text, text, jsonb) to anon, authenticated;

-- ───────────────────────────────────────────────────────────────────────────
-- 7. REALTIME
-- La tablet se entera de un pedido nuevo por acá. Es lo que hace que la
-- comanda salga sola sin que nadie recargue nada.
-- ───────────────────────────────────────────────────────────────────────────

alter publication supabase_realtime add table pedidos;
alter publication supabase_realtime add table impresiones;
