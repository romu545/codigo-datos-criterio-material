# Genera los datos del capítulo 13 (Flujos reproducibles y depuración).
#
# Uso, desde la carpeta raíz del proyecto:
#   Rscript scripts/generar_datos_cap13.R
#
# Necesita datos/cap11/entregas_2026_t1.parquet (scripts/generar_datos_cap11.R).
#
# Produce:
#   datos/cap13/entregas/entregas_2026_01.csv a entregas_2026_03.csv
#       los pedidos del trimestre, un archivo por mes, como los envía el sistema
#   datos/cap13/abril/entregas_2026_04.csv
#       el archivo de abril, que llega con dos cambios sin aviso:
#       el tiempo de entrega viene en minutos (tiempo_entrega_min) y la fecha
#       viene escrita día/mes/año

set.seed(2033)
dir.create("datos/cap13/entregas", showWarnings = FALSE, recursive = TRUE)
dir.create("datos/cap13/abril", showWarnings = FALSE, recursive = TRUE)

entregas <- as.data.frame(arrow::read_parquet(
  "datos/cap11/entregas_2026_t1.parquet"
))
mes <- format(entregas$fecha, "%m")

escribir <- function(df, ruta) {
  write.csv(df, ruta, row.names = FALSE, fileEncoding = "UTF-8", na = "")
}

for (m in c("01", "02", "03")) {
  escribir(
    entregas[mes == m, ],
    sprintf("datos/cap13/entregas/entregas_2026_%s.csv", m)
  )
}

# Abril: pedidos con la misma forma que los de marzo, en fechas de abril
marzo <- entregas[mes == "03", ]
abril <- marzo[sample(nrow(marzo), 820, replace = TRUE), ]
dias_abril <- seq(as.Date("2026-04-01"), as.Date("2026-04-30"), by = "day")
abril$fecha <- sort(sample(dias_abril, nrow(abril), replace = TRUE))
abril$pedido <- sprintf("PD-%05d", 2400 + seq_len(nrow(abril)))

# Los dos cambios que nadie avisó
abril$tiempo_entrega_min <- round(abril$tiempo_entrega_h * 60)
abril$tiempo_entrega_h <- NULL
abril <- abril[, c(
  "pedido",
  "fecha",
  "sucursal",
  "canal",
  "distancia_km",
  "tiempo_entrega_min",
  "unidades",
  "valor_pedido",
  "calificacion",
  "devuelto"
)]
abril$fecha <- format(abril$fecha, "%d/%m/%Y")

escribir(abril, "datos/cap13/abril/entregas_2026_04.csv")
message("Datos del capítulo 13 generados en datos/cap13/")
