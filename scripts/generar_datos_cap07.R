# Genera los datos sintéticos del capítulo 7 (Transformación y limpieza I).
#
# Uso, desde la carpeta raíz del proyecto:
#   Rscript scripts/generar_datos_cap07.R
#
# Produce:
#   datos/cap07/sucursales.csv           (uniones)
#   datos/cap07/productos.csv            (uniones; trae una clave repetida a propósito)
#   datos/cap07/ventas_2026_t1.parquet   (verbos, resúmenes y uniones)
#   datos/cap07/metas_2026_ancho.csv     (formato ancho a largo; separar columnas)
#   datos/cap07/pedidos_web.csv          (separar valores en filas y columnas)
#   datos/cap07/ventas_grande.parquet    (volumen: 10 millones de filas, unos 120 MB;
#                                         no se guarda en el repositorio)
#
# Las sucursales son las del catálogo del capítulo 4 y los NIT, los de la
# tabla de clientes de datos/cap04/operaciones.duckdb.

set.seed(2026)
dir.create("datos/cap07", showWarnings = FALSE, recursive = TRUE)

con <- DBI::dbConnect(
  duckdb::duckdb(),
  dbdir = "datos/cap04/operaciones.duckdb",
  read_only = TRUE
)
clientes <- DBI::dbGetQuery(
  con,
  "SELECT nit, ciudad FROM clientes ORDER BY nit"
)
DBI::dbDisconnect(con)

# 1. Sucursales ---------------------------------------------------------------
sucursales <- data.frame(
  sucursal = sprintf("S%02d", 1:8),
  ciudad = c(
    "Bogotá",
    "Medellín",
    "Cali",
    "Barranquilla",
    "Cartagena",
    "Cúcuta",
    "Pasto",
    "Santa Marta"
  ),
  departamento = c(
    "Bogotá D.C.",
    "Antioquia",
    "Valle del Cauca",
    "Atlántico",
    "Bolívar",
    "Norte de Santander",
    "Nariño",
    "Magdalena"
  ),
  region = c(
    "Andina",
    "Andina",
    "Pacífico",
    "Caribe",
    "Caribe",
    "Andina",
    "Pacífico",
    "Caribe"
  )
)
write.csv(
  sucursales[, c("sucursal", "ciudad", "region")],
  "datos/cap07/sucursales.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

# 2. Productos ----------------------------------------------------------------
productos <- data.frame(
  producto = sprintf("P%02d", 1:12),
  nombre = c(
    "Detergente 1 kg",
    "Jabón de barra x3",
    "Suavizante 1 L",
    "Arroz 5 kg",
    "Aceite 3 L",
    "Café 500 g",
    "Azúcar 2,5 kg",
    "Gaseosa 1,5 L",
    "Agua 6 L",
    "Jugo 1 L",
    "Limpiador multiusos",
    "Papel higiénico x12"
  ),
  categoria = c(
    "Aseo",
    "Aseo",
    "Aseo",
    "Alimentos",
    "Alimentos",
    "Alimentos",
    "Alimentos",
    "Bebidas",
    "Bebidas",
    "Bebidas",
    "Aseo",
    "Aseo"
  ),
  precio_lista = c(
    18900,
    9500,
    15400,
    21900,
    32500,
    16800,
    11200,
    6500,
    8900,
    5200,
    12700,
    27900
  )
)
# Problema sembrado: el producto P07 quedó dos veces en el catálogo
productos <- rbind(productos, productos[7, ])
write.csv(
  productos,
  "datos/cap07/productos.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

# 3. Ventas del primer trimestre ---------------------------------------------
n <- 6000
fechas <- seq(as.Date("2026-01-02"), as.Date("2026-03-31"), by = "day")
peso_sucursal <- c(1.3, 1.2, 1.1, 1, 0.9, 0.8, 0.8, 0.9)
producto_venta <- sample(sprintf("P%02d", 1:12), n, replace = TRUE)
precio <- productos$precio_lista[match(producto_venta, productos$producto)]

ventas <- data.frame(
  id_venta = seq_len(n),
  fecha = sort(sample(fechas, n, replace = TRUE)),
  sucursal = sample(
    sucursales$sucursal,
    n,
    replace = TRUE,
    prob = peso_sucursal
  ),
  nit = sample(clientes$nit, n, replace = TRUE),
  producto = producto_venta,
  unidades = sample(1:40, n, replace = TRUE, prob = 40:1),
  precio_unitario = precio,
  descuento = sample(c(0, 0, 0, 0.05, 0.1), n, replace = TRUE)
)
arrow::write_parquet(ventas, "datos/cap07/ventas_2026_t1.parquet")

# 4. Metas mensuales en formato ancho ----------------------------------------
meses <- c(
  "ene",
  "feb",
  "mar",
  "abr",
  "may",
  "jun",
  "jul",
  "ago",
  "sep",
  "oct",
  "nov",
  "dic"
)
base <- c(72, 66, 60, 56, 52, 46, 45, 49) # millones de pesos al mes
metas <- data.frame(
  sucursal = sucursales$sucursal,
  ciudad_departamento = paste(
    sucursales$ciudad,
    sucursales$departamento,
    sep = " - "
  )
)
for (i in seq_along(meses)) {
  metas[[paste0("meta_", meses[i])]] <- round(
    base * (1 + 0.015 * (i - 1)) * runif(8, 0.95, 1.05),
    1
  )
}
write.csv(
  metas,
  "datos/cap07/metas_2026_ancho.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

# 5. Pedidos de la tienda en línea --------------------------------------------
m <- 250
items <- vapply(
  seq_len(m),
  function(i) {
    k <- sample(1:4, 1, prob = c(4, 3, 2, 1))
    p <- sort(sample(sprintf("P%02d", 1:12), k))
    paste0(p, " x", sample(1:6, k, replace = TRUE), collapse = "; ")
  },
  character(1)
)
pedidos <- data.frame(
  pedido = sprintf(
    "WEB-%s-%05d",
    sample(c("BOG", "MED", "CAL", "BAQ"), m, replace = TRUE),
    seq_len(m) + 1200
  ),
  fecha = sort(sample(fechas, m, replace = TRUE)),
  nit = sample(clientes$nit, m, replace = TRUE),
  items = items,
  contacto = sample(
    c(
      "Ana Ríos <ana.rios@correo.co>",
      "Luis Peña <lpena@empresa.com.co>",
      "Marta Gil <compras@distrigil.co>",
      "Juan Ospina <juan.ospina@correo.co>"
    ),
    m,
    replace = TRUE
  )
)
write.csv(
  pedidos,
  "datos/cap07/pedidos_web.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

# 6. Ventas grandes (volumen), con DuckDB y sin pasar por la memoria de R ------
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(
  con,
  r"(
  COPY (
    SELECT
      i + 1                                                    AS id_venta,
      DATE '2024-01-01' + CAST(hash(i || '-fecha') % 821 AS INTEGER) AS fecha,
      'S0' || CAST(hash(i || '-sucursal') % 8 + 1 AS VARCHAR)    AS sucursal,
      'P' || lpad(CAST(hash(i || '-producto') % 12 + 1 AS VARCHAR), 2, '0') AS producto,
      CAST(hash(i || '-unidades') % 40 + 1 AS INTEGER)            AS unidades,
      round(5000 + (hash(i || '-valor') % 3000000) / 100, 2)      AS valor_venta
    FROM range(10000000) AS r(i)
  ) TO 'datos/cap07/ventas_grande.parquet' (FORMAT parquet)
)"
)
DBI::dbDisconnect(con)

message("Datos del capítulo 7 generados en datos/cap07/")
