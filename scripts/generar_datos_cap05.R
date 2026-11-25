# Genera los datos sintéticos del capítulo 5 (Importación de datos III).
#
# Uso, desde la carpeta raíz del proyecto:
#   Rscript scripts/generar_datos_cap05.R
#
# Produce:
#   datos/cap05/cartera_clientes_2026_02.csv  (ejemplos 5.1 a 5.6)
#   datos/cap05/visitas_comerciales.xlsx      (ejercicio 5.1)
#
# Los NIT se toman de datos/cap04/operaciones.duckdb para que coincidan
# con los clientes de los capítulos anteriores.

set.seed(2026)

dir.create("datos/cap05", showWarnings = FALSE, recursive = TRUE)

# Clientes del capítulo 4 ---------------------------------------------------
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "datos/cap04/operaciones.duckdb",
                      read_only = TRUE)
clientes <- DBI::dbGetQuery(con, "SELECT nit, ciudad FROM clientes ORDER BY nit")
DBI::dbDisconnect(con)

# 1. Cartera de clientes, febrero de 2026 -----------------------------------
n <- 60
idx <- sample(nrow(clientes), n)

emision <- sort(as.Date("2026-02-01") + sample(0:27, n, replace = TRUE))
vencimiento <- emision + 30
pagada <- runif(n) < 0.55
pago <- emision + sample(5:40, n, replace = TRUE)
valor <- round(runif(n, 150000, 9500000), 2)

# Formato contable colombiano: punto de miles y coma decimal
formato_pesos <- function(x) {
  formatC(x, format = "f", digits = 2, big.mark = ".", decimal.mark = ",")
}

dmy_texto <- function(x) format(x, "%d/%m/%Y")

# Variantes reales de "sí" y "no" escritas a mano
si <- c("SI", "SI", "SI", "Sí", "si")
no <- c("NO", "NO", "NO", "No", "no")
pago_texto <- ifelse(pagada, sample(si, n, replace = TRUE),
                     sample(no, n, replace = TRUE))

ciudad <- clientes$ciudad[idx]
ciudad[sample(n, 5)] <- "SIN DATO"

calificacion <- as.character(sample(1:5, n, replace = TRUE))
calificacion[sample(n, 7)] <- "999"       # código del sistema: sin calificar

# Saldo: en formato contable, el cero se muestra como "-"
saldo <- ifelse(pagada, "-", formato_pesos(valor))

# Hora de registro en el sistema, en UTC (formato ISO 8601)
registro <- as.POSIXct(emision, tz = "UTC") +
  sample((12 * 3600):(23 * 3600), n, replace = TRUE)
registro_texto <- format(registro, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

cartera <- data.frame(
  `N° Factura`          = sprintf("FV-%04d", 1001:(1000 + n)),
  `NIT Cliente`         = clientes$nit[idx],
  `Fecha Emisión`       = dmy_texto(emision),
  `Fecha Vencimiento`   = dmy_texto(vencimiento),
  `Fecha Pago`          = ifelse(pagada, dmy_texto(pago), "N/A"),
  `Valor Factura ($)`   = formato_pesos(valor),
  `¿Pagó?`              = pago_texto,
  `Cliente Activo`      = sample(c("S", "S", "S", "N"), n, replace = TRUE),
  `Calificación Riesgo` = calificacion,
  `Ciudad`              = ciudad,
  `Saldo Pendiente`     = saldo,
  `Registrado En`       = registro_texto,
  `Observaciones`       = "",
  `Columna1`            = "",
  `Columna2`            = "",
  check.names = FALSE
)



# Exportación típica desde una hoja de cálculo: ";" como separador y un
# separador sobrante al final de cada línea, que crea una columna sin nombre.
lineas <- c(
  paste0(paste(names(cartera), collapse = ";"), ";"),
  paste0(apply(cartera, 1, paste, collapse = ";"), ";")
)
writeLines(enc2utf8(lineas), "datos/cap05/cartera_clientes_2026_02.csv",
           useBytes = TRUE)

# 2. Visitas comerciales (Excel), para el ejercicio ---------------------------
m <- 40
fecha_visita <- as.Date("2026-02-02") + sample(0:25, m, replace = TRUE)
visitas <- data.frame(
  `Fecha Visita`   = fecha_visita,
  `Cód. Sucursal`  = sprintf("S%02d", sample(1:8, m, replace = TRUE)),
  `Asesor`         = sample(c("Ana Ríos", "Luis Peña", "Marta Gil", "Juan Ospina"),
                            m, replace = TRUE),
  `¿Hubo Venta?`   = ifelse(runif(m) < 0.4, "X", NA),
  `Duración (min)` = as.character(sample(15:120, m, replace = TRUE)),
  `Columna1`       = NA_character_,
  `Columna2`       = NA_character_,
  check.names = FALSE
)
visitas <- visitas[order(visitas$`Fecha Visita`), ]
visitas$`Duración (min)`[sample(m, 4)] <- "-"   # el asesor no la registró

wb <- openxlsx2::wb_workbook()
wb$add_worksheet("Visitas")
wb$add_data(x = visitas, na.strings = "")

# Algunas fechas fueron escritas a mano como texto: Excel no las reconoce
filas_texto <- sort(sample(seq_len(m), 6)) + 1   # +1 por el encabezado
for (f in filas_texto) {
  wb$add_data(x = format(visitas$`Fecha Visita`[f - 1], "%d/%m/%Y"),
              dims = paste0("A", f))
}
wb$save("datos/cap05/visitas_comerciales.xlsx")

message("Datos del capítulo 5 generados en datos/cap05/")
