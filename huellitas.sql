-- ============================================================
-- Base de datos: Huellitas
-- Tienda de mascotas
-- Tablas: catalogo, clientes, transacciones, detalle_transaccion
-- ============================================================

CREATE DATABASE IF NOT EXISTS huellitas
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE huellitas;

-- ------------------------------------------------------------
-- Catálogo de productos
-- ------------------------------------------------------------
CREATE TABLE catalogo (
  id_producto        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  codigo             VARCHAR(20)  NOT NULL,
  nombre             VARCHAR(120) NOT NULL,
  descripcion        VARCHAR(500) NULL,
  categoria          VARCHAR(60)  NOT NULL,
  especie            VARCHAR(40)  NULL COMMENT 'Perro, Gato, Ave, Roedor, General',
  marca              VARCHAR(80)  NULL,
  presentacion       VARCHAR(60)  NULL COMMENT 'Ej: bolsa 2 kg, unidad, lata 400 g',
  precio_unitario    DECIMAL(12,2) NOT NULL,
  stock              INT UNSIGNED NOT NULL DEFAULT 0,
  stock_minimo       INT UNSIGNED NOT NULL DEFAULT 5,
  activo             TINYINT(1)   NOT NULL DEFAULT 1,
  creado_en          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_catalogo_codigo (codigo),
  KEY idx_catalogo_categoria (categoria),
  KEY idx_catalogo_nombre (nombre),
  CONSTRAINT chk_catalogo_precio CHECK (precio_unitario >= 0),
  CONSTRAINT chk_catalogo_stock  CHECK (stock >= 0)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Clientes
-- ------------------------------------------------------------
CREATE TABLE clientes (
  id_cliente         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tipo_documento     ENUM('CC','CE','NIT','PAS','TI') NOT NULL DEFAULT 'CC',
  documento          VARCHAR(20)  NOT NULL,
  nombre             VARCHAR(80)  NOT NULL,
  apellido           VARCHAR(80)  NOT NULL,
  telefono           VARCHAR(20)  NULL,
  correo             VARCHAR(120) NULL,
  direccion          VARCHAR(180) NULL,
  ciudad             VARCHAR(80)  NULL,
  fecha_registro     DATE         NOT NULL DEFAULT (CURRENT_DATE),
  activo             TINYINT(1)   NOT NULL DEFAULT 1,
  creado_en          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_clientes_documento (tipo_documento, documento),
  KEY idx_clientes_nombre (apellido, nombre),
  KEY idx_clientes_correo (correo)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Transacciones (encabezado de venta)
-- ------------------------------------------------------------
CREATE TABLE transacciones (
  id_transaccion     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  numero_factura     VARCHAR(20)  NOT NULL,
  id_cliente         INT UNSIGNED NOT NULL,
  fecha              DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  metodo_pago        ENUM('Efectivo','Tarjeta','Transferencia','Nequi','Daviplata','Otro') NOT NULL DEFAULT 'Efectivo',
  estado             ENUM('Pendiente','Pagada','Anulada') NOT NULL DEFAULT 'Pagada',
  subtotal           DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  descuento          DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  impuesto           DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total              DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  observaciones      VARCHAR(300) NULL,
  creado_en          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_transacciones_factura (numero_factura),
  KEY idx_transacciones_cliente (id_cliente),
  KEY idx_transacciones_fecha (fecha),
  CONSTRAINT fk_transacciones_cliente
    FOREIGN KEY (id_cliente) REFERENCES clientes (id_cliente)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT chk_transacciones_montos CHECK (
    subtotal >= 0 AND descuento >= 0 AND impuesto >= 0 AND total >= 0
  )
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Detalle de cada transacción (líneas de venta)
-- ------------------------------------------------------------
CREATE TABLE detalle_transaccion (
  id_detalle         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_transaccion     INT UNSIGNED NOT NULL,
  id_producto        INT UNSIGNED NOT NULL,
  cantidad           INT UNSIGNED NOT NULL,
  precio_unitario    DECIMAL(12,2) NOT NULL COMMENT 'Precio al momento de la venta',
  descuento_linea    DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  subtotal_linea     DECIMAL(12,2) NOT NULL,
  KEY idx_detalle_transaccion (id_transaccion),
  KEY idx_detalle_producto (id_producto),
  CONSTRAINT fk_detalle_transaccion
    FOREIGN KEY (id_transaccion) REFERENCES transacciones (id_transaccion)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_detalle_producto
    FOREIGN KEY (id_producto) REFERENCES catalogo (id_producto)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT chk_detalle_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_detalle_precios CHECK (
    precio_unitario >= 0 AND descuento_linea >= 0 AND subtotal_linea >= 0
  )
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Datos de ejemplo: catálogo
-- ------------------------------------------------------------
INSERT INTO catalogo
  (codigo, nombre, descripcion, categoria, especie, marca, presentacion, precio_unitario, stock, stock_minimo)
VALUES
  ('ALI-001', 'Alimento seco adulto', 'Croquetas balanceadas para perro adulto', 'Alimento', 'Perro', 'NutriPet', 'Bolsa 4 kg', 68500.00, 40, 8),
  ('ALI-002', 'Alimento húmedo gato', 'Pate de pollo para gato adulto', 'Alimento', 'Gato', 'MiauMix', 'Lata 400 g', 8900.00, 60, 12),
  ('ACC-001', 'Collar ajustable', 'Collar de nylon con hebilla', 'Accesorio', 'Perro', 'Huellitas', 'Unidad', 18500.00, 25, 5),
  ('ACC-002', 'Arenero cubierto', 'Arenero con tapa y pala', 'Accesorio', 'Gato', 'CasaFelina', 'Unidad', 42000.00, 12, 3),
  ('JUG-001', 'Pelota de caucho', 'Pelota resistente para mordida', 'Juguete', 'Perro', 'PlayPet', 'Unidad', 12000.00, 30, 6),
  ('HIG-001', 'Shampoo neutro', 'Shampoo hipoalergénico', 'Higiene', 'General', 'SoftCoat', 'Frasco 500 ml', 24500.00, 18, 4),
  ('SAL-001', 'Arena sanitaria', 'Arena aglomerante sin perfume', 'Higiene', 'Gato', 'CleanPaw', 'Bolsa 5 kg', 19800.00, 35, 8);

-- ------------------------------------------------------------
-- Datos de ejemplo: clientes
-- ------------------------------------------------------------
INSERT INTO clientes
  (tipo_documento, documento, nombre, apellido, telefono, correo, direccion, ciudad)
VALUES
  ('CC', '1094123456', 'Laura', 'Gómez', '3105550101', 'laura.gomez@email.com', 'Cra 8 #12-40', 'Pereira'),
  ('CC', '1085987654', 'Andrés', 'Ríos', '3125550202', 'andres.rios@email.com', 'Calle 19 #7-15', 'Pereira'),
  ('NIT', '900123456', 'Veterinaria El Parque', 'SAS', '6063334455', 'contacto@elparque.com', 'Av. Circunvalar 45', 'Dosquebradas');

-- ------------------------------------------------------------
-- Datos de ejemplo: transacciones y detalle
-- ------------------------------------------------------------
INSERT INTO transacciones
  (numero_factura, id_cliente, fecha, metodo_pago, estado, subtotal, descuento, impuesto, total, observaciones)
VALUES
  ('FAC-0001', 1, '2026-09-28 10:15:00', 'Efectivo', 'Pagada', 80500.00, 0.00, 0.00, 80500.00, 'Compra mostrador'),
  ('FAC-0002', 2, '2026-09-30 16:40:00', 'Nequi', 'Pagada', 61800.00, 2000.00, 0.00, 59800.00, NULL);

INSERT INTO detalle_transaccion
  (id_transaccion, id_producto, cantidad, precio_unitario, descuento_linea, subtotal_linea)
VALUES
  (1, 1, 1, 68500.00, 0.00, 68500.00),
  (1, 5, 1, 12000.00, 0.00, 12000.00),
  (2, 2, 2, 8900.00, 0.00, 17800.00),
  (2, 7, 2, 19800.00, 0.00, 39600.00),
  (2, 6, 1, 24500.00, 2000.00, 22500.00);

-- ------------------------------------------------------------
--                                              Consulta de verificación 
-- ------------------------------------------------------------
-- SELECT c.nombre, t.id_transaccion
-- FROM clientes c
-- LEFT JOIN transacciones t ON c.id_cliente = t.id_cliente;

-- ------------------------------------------------------------
-- JOIN multi-tabla 
-- ------------------------------------------------------------
-- SELECT t.numero_factura,  t.fecha,  CONCAT(c.nombre, ' ', c.apellido) AS cliente,  p.codigo,  p.nombre AS producto,  p.categoria,  d.cantidad,  d.precio_unitario,  d.subtotal_linea,  t.total AS total_factura
-- FROM transacciones t
-- INNER JOIN clientes c  ON c.id_cliente = t.id_cliente
-- INNER JOIN detalle_transaccion d  ON d.id_transaccion = t.id_transaccion
-- INNER JOIN catalogo p  ON p.id_producto = d.id_producto
-- ORDER BY t.fecha, t.numero_factura, d.id_detalle;

-- ------------------------------------------------------------
-- UNION
-- ------------------------------------------------------------
-- SELECT nombre, 'cliente' AS tipo
-- FROM clientes
-- UNION
-- SELECT nombre, 'producto' AS tipo
-- FROM catalogo
-- ORDER BY tipo, nombre;

-- ------------------------------------------------------------
--              Subconsulta     correlacionada
-- Total gastado por cliente
-- ------------------------------------------------------------

-- SELECT  c.nombre,  c.apellido,  (    SELECT COALESCE(SUM(t.total), 0)    
-- FROM transacciones t
--     WHERE t.id_cliente = c.id_cliente
--       AND t.estado = 'Pagada'
--   ) AS total_comprado
-- FROM clientes c
-- ORDER BY total_comprado DESC;
