# Genera los datos sintéticos del capítulo 9 (Transformación y limpieza III).
#
# Uso, desde la carpeta raíz del proyecto:
#   Rscript scripts/generar_datos_cap09.R
#
# Necesita datos/cap07/ventas_2026_t1.parquet y datos/cap07/productos.csv
# (se generan con scripts/generar_datos_cap07.R).
#
# Produce:
#   datos/cap09/indicadores/*.csv       (muchas tablas: reducir una lista de uniones;
#                                        devoluciones trae una fila repetida y a
#                                        visitas le falta una sucursal en marzo)
#   datos/cap09/precios_historial.csv   (unir por la fecha vigente)
#   datos/cap09/tramos_comision.csv     (unir por rangos)
#   datos/cap09/conteos/conteo_S0*.csv  (iterar con errores: S04 trae un texto en
#                                        las unidades y S07 otro nombre de columna)

set.seed(2029)
dir.create("datos/cap09/indicadores", showWarnings = FALSE, recursive = TRUE)
dir.create("datos/cap09/conteos", showWarnings = FALSE, recursive = TRUE)

ventas <- arrow::read_parquet("datos/cap07/ventas_2026_t1.parquet")
productos <- unique(read.csv("datos/cap07/productos.csv"))
sucursales <- sprintf("S%02d", 1:8)

escribir <- function(df, ruta) {
  write.csv(df, ruta, row.names = FALSE, fileEncoding = "UTF-8", na = "")
}

# 1. Indicadores mensuales por sucursal, un archivo por indicador ------------
ventas$mes <- as.integer(format(ventas$fecha, "%m"))
ventas$valor_neto <- ventas$unidades *
  ventas$precio_unitario *
  (1 - ventas$descuento)
ventas_mes <- aggregate(valor_neto ~ sucursal + mes, data = ventas, FUN = sum)
names(ventas_mes)[3] <- "valor_ventas"
ventas_mes <- ventas_mes[order(ventas_mes$sucursal, ventas_mes$mes), ]
ventas_mes$valor_ventas <- round(ventas_mes$valor_ventas)
escribir(ventas_mes, "datos/cap09/indicadores/ventas_mes.csv")

recaudos_mes <- ventas_mes[c("sucursal", "mes")]
recaudos_mes$valor_recaudado <- round(
  ventas_mes$valor_ventas *
    runif(nrow(ventas_mes), 0.80, 0.98),
  -3
)
escribir(recaudos_mes, "datos/cap09/indicadores/recaudos_mes.csv")

visitas_mes <- ventas_mes[c("sucursal", "mes")]
visitas_mes$visitas <- sample(35:90, nrow(visitas_mes), replace = TRUE)
# Problema sembrado: S07 no reportó las visitas de marzo
visitas_mes <- visitas_mes[
  !(visitas_mes$sucursal == "S07" & visitas_mes$mes == 3),
]
escribir(visitas_mes, "datos/cap09/indicadores/visitas_mes.csv")

devoluciones_mes <- ventas_mes[c("sucursal", "mes")]
devoluciones_mes$devoluciones <- sample(
  0:12,
  nrow(devoluciones_mes),
  replace = TRUE
)
# Problema sembrado: la fila de S04 en febrero quedó dos veces
fila <- which(devoluciones_mes$sucursal == "S04" & devoluciones_mes$mes == 2)
devoluciones_mes <- devoluciones_mes[
  sort(c(seq_len(nrow(devoluciones_mes)), fila)),
]
escribir(devoluciones_mes, "datos/cap09/indicadores/devoluciones_mes.csv")

# 2. Historial de precios ----------------------------------------------------
# La lista inicial es el precio de lista del catálogo. Dos ajustes en el
# trimestre que el sistema de ventas no aplicó: las ventas siguen al precio viejo.
sube_feb <- c("P01", "P04", "P05", "P08", "P11")
sube_mar <- c("P02", "P06", "P09")
precios <- data.frame(
  producto = productos$producto,
  vigente_desde = as.Date("2025-07-01"),
  precio = productos$precio_lista
)
ajuste <- function(cod, desde, factor) {
  base <- productos$precio_lista[match(cod, productos$producto)]
  data.frame(
    producto = cod,
    vigente_desde = as.Date(desde),
    precio = round(base * factor, -2)
  )
}
precios <- rbind(
  precios,
  ajuste(sube_feb, "2026-02-01", 1.06),
  ajuste(sube_mar, "2026-03-01", 1.04)
)
precios <- precios[order(precios$producto, precios$vigente_desde), ]
escribir(precios, "datos/cap09/precios_historial.csv")

# 3. Tramos de comisión según las ventas del mes -----------------------------
tramos <- data.frame(
  tramo = c("A", "B", "C", "D"),
  desde = c(0, 45e6, 60e6, 72e6),
  hasta = c(45e6, 60e6, 72e6, NA),
  comision_pct = c(1, 1.5, 2, 2.5)
)
escribir(tramos, "datos/cap09/tramos_comision.csv")

# 4. Conteos físicos de inventario, un archivo por sucursal -----------------
for (s in sucursales) {
  conteo <- data.frame(
    producto = productos$producto,
    unidades_contadas = sample(20:400, nrow(productos)),
    fecha_conteo = "2026-03-31"
  )
  conteo$unidades_contadas <- as.character(conteo$unidades_contadas)
  # Problemas sembrados
  if (s == "S04") {
    conteo$unidades_contadas[9] <- "N/D"
  }
  if (s == "S07") {
    names(conteo)[2] <- "cantidad"
  }
  escribir(conteo, sprintf("datos/cap09/conteos/conteo_%s.csv", s))
}

message("Datos del capítulo 9 generados en datos/cap09/")
