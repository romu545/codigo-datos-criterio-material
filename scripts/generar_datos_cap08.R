# Genera los datos sintéticos del capítulo 8 (Transformación y limpieza II).
#
# Uso, desde la carpeta raíz del proyecto:
#   Rscript scripts/generar_datos_cap08.R
#
# Produce:
#   datos/cap08/clientes_crm.csv   (ejemplos 8.1 a 8.4): exportación del sistema
#                                  de gestión de clientes, con textos escritos de
#                                  varias formas y clientes registrados más de una vez.
#
# La cartera que se limpia en el capítulo es la del capítulo 6
# (datos/cap06/cartera_2026_t1.parquet), con sus clientes.

set.seed(2026)
dir.create("datos/cap08", showWarnings = FALSE, recursive = TRUE)

clientes <- arrow::read_parquet("datos/cap06/clientes.parquet")

# Cuántas veces aparece cada cliente en el CRM
veces <- sample(1:3, nrow(clientes), replace = TRUE, prob = c(0.72, 0.22, 0.06))
crm <- clientes[
  rep(seq_len(nrow(clientes)), veces),
  c("nit", "razon_social", "ciudad")
]
n <- nrow(crm)

sin_tildes <- function(x) chartr("áéíóúÁÉÍÓÚñÑ", "aeiouAEIOUnN", x)
elegir <- function(opciones, prob) sample(opciones, 1, prob = prob)

# NIT: con puntos, sin el cero inicial o con espacios
crm$nit <- vapply(
  crm$nit,
  function(nit) {
    sin_cero <- sub("^0", "", nit)
    conpuntos <- sub("^(\\d{1,3})(\\d{3})(\\d{3})$", "\\1.\\2.\\3", sin_cero)
    elegir(
      c(nit, sin_cero, conpuntos, paste0(" ", nit)),
      c(0.75, 0.1, 0.1, 0.05)
    )
  },
  character(1),
  USE.NAMES = FALSE
)

# Razón social: mayúsculas, sin tildes, sin puntos, espacios de más
crm$razon_social <- vapply(
  crm$razon_social,
  function(r) {
    elegir(
      c(
        r,
        toupper(r),
        sin_tildes(r),
        gsub(".", "", r, fixed = TRUE),
        paste0(gsub(" ", "  ", r), " ")
      ),
      c(0.6, 0.12, 0.1, 0.1, 0.08)
    )
  },
  character(1),
  USE.NAMES = FALSE
)

# Ciudad: variantes de escritura, sinónimos y errores de digitación
variantes <- list(
  "Bogotá" = list(
    c("Bogotá", "BOGOTA", "Bogota", "bogotá", "Bogotá D.C.", "Bogota D.C."),
    c(0.5, 0.15, 0.1, 0.05, 0.12, 0.08)
  ),
  "Medellín" = list(
    c("Medellín", "MEDELLIN", "Medellin", "Medelin"),
    c(0.6, 0.15, 0.15, 0.1)
  ),
  "Cali" = list(
    c("Cali", "CALI", " Cali", "Santiago de Cali"),
    c(0.65, 0.15, 0.1, 0.1)
  ),
  "Barranquilla" = list(
    c("Barranquilla", "BARRANQUILLA", "B/quilla", "Barranqilla"),
    c(0.65, 0.15, 0.12, 0.08)
  ),
  "Cartagena" = list(
    c("Cartagena", "CARTAGENA", "Cartagena de Indias"),
    c(0.7, 0.15, 0.15)
  ),
  "Cúcuta" = list(c("Cúcuta", "CUCUTA", "Cucuta"), c(0.65, 0.2, 0.15)),
  "Pasto" = list(c("Pasto", "PASTO", "pasto"), c(0.75, 0.15, 0.1)),
  "Santa Marta" = list(
    c("Santa Marta", "SANTA MARTA", "Santa  Marta"),
    c(0.7, 0.15, 0.15)
  )
)
crm$ciudad <- vapply(
  crm$ciudad,
  function(c) {
    v <- variantes[[c]]
    elegir(v[[1]], v[[2]])
  },
  character(1),
  USE.NAMES = FALSE
)
crm$ciudad[sample(n, 6)] <- NA

# Teléfono: el mismo número en formatos distintos
indicativo <- c(
  "Bogotá" = "601",
  "Medellín" = "604",
  "Cali" = "602",
  "Barranquilla" = "605",
  "Cartagena" = "605",
  "Cúcuta" = "607",
  "Pasto" = "602",
  "Santa Marta" = "605"
)
base_tel <- ifelse(
  runif(n) < 0.4,
  paste0(
    "3",
    sample(00:24, n, replace = TRUE) |> sprintf(fmt = "%02d"),
    sprintf("%07d", sample(1e6:9999999, n, replace = TRUE))
  ),
  paste0(
    indicativo[clientes$ciudad[rep(seq_len(nrow(clientes)), veces)]],
    sprintf("%07d", sample(2e6:8999999, n, replace = TRUE))
  )
)
crm$telefono <- vapply(
  base_tel,
  function(t) {
    elegir(
      c(
        t,
        paste0(
          "(",
          substr(t, 1, 3),
          ") ",
          substr(t, 4, 6),
          " ",
          substr(t, 7, 10)
        ),
        paste(substr(t, 1, 3), substr(t, 4, 6), substr(t, 7, 10), sep = "-"),
        paste0("+57 ", t),
        substr(t, 4, 10),
        "N/A"
      ),
      c(0.45, 0.15, 0.12, 0.15, 0.07, 0.06)
    )
  },
  character(1),
  USE.NAMES = FALSE
)

# Correo: mayúsculas, espacios, faltantes y alguno sin dominio completo
dominio <- tolower(gsub("[^A-Za-z0-9]", "", sin_tildes(clientes$razon_social)))
dominio <- dominio[rep(seq_len(nrow(clientes)), veces)]
correo <- paste0(
  sample(
    c("compras", "cartera", "gerencia", "contabilidad"),
    n,
    replace = TRUE
  ),
  "@",
  dominio,
  ".com.co"
)
crm$correo <- vapply(
  correo,
  function(c) {
    elegir(
      c(c, toupper(c), paste0(" ", c, " "), sub("\\.com\\.co$", "", c), NA),
      c(0.6, 0.1, 0.1, 0.08, 0.12)
    )
  },
  character(1),
  USE.NAMES = FALSE
)

# Contacto: espacios de más y mayúsculas mezcladas
nombres <- c(
  "María Pérez",
  "Andrés Gómez",
  "Luisa Fernández",
  "Jorge Ramírez",
  "Camila Díaz",
  "Óscar Muñoz",
  "Natalia Ríos",
  "Felipe Castaño",
  "Paula Ortiz",
  "Julián Peña"
)
crm$contacto <- vapply(
  sample(nombres, n, replace = TRUE),
  function(x) {
    elegir(
      c(x, toupper(x), tolower(x), paste0("  ", gsub(" ", "   ", x))),
      c(0.55, 0.2, 0.1, 0.15)
    )
  },
  character(1),
  USE.NAMES = FALSE
)

crm$actualizado <- as.Date("2024-01-01") + sample(0:820, n, replace = TRUE)

crm <- crm[sample(n), ]
crm <- data.frame(
  registro = sprintf("CRM-%04d", seq_len(n)),
  crm,
  row.names = NULL
)
crm <- crm[, c(
  "registro",
  "nit",
  "razon_social",
  "ciudad",
  "telefono",
  "correo",
  "contacto",
  "actualizado"
)]

write.csv(
  crm,
  "datos/cap08/clientes_crm.csv",
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
message("Datos del capítulo 8 generados en datos/cap08/ (", n, " registros)")
