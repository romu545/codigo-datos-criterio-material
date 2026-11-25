# Genera los datos sintéticos del capítulo 6 (Tipos de datos y calidad).
#
# Uso, desde la carpeta raíz del proyecto:
#   Rscript scripts/generar_datos_cap06.R
#
# Produce:
#   datos/cap06/cartera_2026_t1.parquet   (ejemplos 6.1 a 6.6)
#   datos/cap06/clientes.parquet          (integridad referencial)
#   datos/cap06/recaudos_2026_t1.parquet  (ejercicio 6.1)
#
# La cartera tiene la misma estructura que deja el contrato del capítulo 5,
# ya con tipos correctos, y problemas de calidad sembrados a propósito. Cada
# problema se marca abajo con un comentario «Problema:».

set.seed(2026)

dir.create("datos/cap06", showWarnings = FALSE, recursive = TRUE)

# Clientes del capítulo 4 ---------------------------------------------------
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "datos/cap04/operaciones.duckdb",
                      read_only = TRUE)
clientes <- DBI::dbGetQuery(con, "SELECT * FROM clientes ORDER BY nit")
DBI::dbDisconnect(con)

arrow::write_parquet(clientes, "datos/cap06/clientes.parquet")

# 1. Cartera del primer trimestre de 2026 -----------------------------------
n <- 400
corte <- as.Date("2026-03-31")
idx <- sample(nrow(clientes), n, replace = TRUE)

emision <- sort(as.Date("2026-01-02") + sample(0:88, n, replace = TRUE))
vencimiento <- emision + 30
pago <- emision + sample(3:45, n, replace = TRUE)
pagada <- runif(n) < 0.65 & pago <= corte
valor <- round(runif(n, 150000, 9500000), 2)

calificacion <- sample(1:5, n, replace = TRUE)
calificacion[sample(n, 10)] <- NA

registro <- as.POSIXct(emision, tz = "UTC") +
  sample((12 * 3600):(23 * 3600), n, replace = TRUE)
attr(registro, "tzone") <- "America/Bogota"

cartera <- data.frame(
  factura           = sprintf("FV-%05d", 20001:(20000 + n)),
  nit               = clientes$nit[idx],
  fecha_emision     = emision,
  fecha_vencimiento = vencimiento,
  fecha_pago        = as.Date(ifelse(pagada, pago, NA)),
  valor_factura     = valor,
  pagada            = pagada,
  cliente_activo    = runif(n) < 0.85,
  calificacion      = calificacion,
  ciudad            = clientes$ciudad[idx],
  saldo             = ifelse(pagada, 0, valor),
  registrado_en     = registro
)

# Filas disponibles para sembrar problemas sin que se pisen entre sí
libres <- seq_len(n)
tomar <- function(k, candidatas = libres) {
  candidatas <- intersect(candidatas, libres)
  elegidas <- candidatas[sample.int(length(candidatas), k)]
  libres <<- setdiff(libres, elegidas)
  elegidas
}

# Problema: la misma ciudad escrita de varias formas
bogota <- which(cartera$ciudad == "Bogotá")
cartera$ciudad[tomar(6, bogota)] <- "BOGOTA"
cartera$ciudad[tomar(3, bogota)] <- "Bogota D.C."
cali <- which(cartera$ciudad == "Cali")
cartera$ciudad[tomar(2, cali)] <- " Cali"
cartera$ciudad[tomar(4)] <- NA

# Problema: NIT faltante
cartera$nit[tomar(3)] <- NA

# Problema: NIT que pasó por una columna numérica y perdió el cero inicial
con_cero <- which(startsWith(cartera$nit, "0"))
f <- tomar(4, con_cero)
cartera$nit[f] <- sub("^0", "", cartera$nit[f])

# Problema: NIT que no existe en la tabla de clientes
f <- tomar(3)
cartera$nit[f] <- c("0900123456", "0900123456", "0811000222")

# Problema: valores imposibles en la factura
no_pagadas <- which(!cartera$pagada)
f <- tomar(2, no_pagadas)
cartera$valor_factura[f] <- -cartera$valor_factura[f]
cartera$saldo[f] <- cartera$valor_factura[f]
f <- tomar(1, no_pagadas)
cartera$valor_factura[f] <- 0
cartera$saldo[f] <- 0

# Problema: un valor posible, pero muy alto (para revisar, no necesariamente un error)
f <- tomar(1, no_pagadas)
cartera$valor_factura[f] <- 98500000
cartera$saldo[f] <- 98500000

# Problema: calificación fuera del dominio 1 a 5
cartera$calificacion[tomar(2)] <- 0L
cartera$calificacion[tomar(1)] <- 7L

# Problema: año mal digitado (2062 en lugar de 2026)
f <- tomar(1, no_pagadas)
cartera$fecha_emision[f] <- as.Date(sub("^2026", "2062", format(cartera$fecha_emision[f])))

# Problema: pago anterior a la emisión
pagadas <- which(cartera$pagada)
f <- tomar(3, pagadas)
cartera$fecha_pago[f] <- cartera$fecha_emision[f] - sample(5:20, 3)

# Problema: marcada como pagada, pero con saldo pendiente
f <- tomar(3, pagadas)
cartera$saldo[f] <- round(cartera$valor_factura[f] * 0.4, 2)

# Problema: marcada como no pagada, pero con fecha de pago
f <- tomar(2, no_pagadas)
cartera$fecha_pago[f] <- cartera$fecha_emision[f] + 12

# Problema: saldo mayor que el valor de la factura
f <- tomar(2, no_pagadas)
cartera$saldo[f] <- cartera$valor_factura[f] * 10

# Problema: filas repetidas por una doble exportación
repetidas <- cartera[tomar(4), ]

# Problema: la misma factura con dos versiones distintas
f <- tomar(2, pagadas)
versiones <- cartera[f, ]
versiones$valor_factura <- round(versiones$valor_factura * 1.08, 2)

cartera <- rbind(cartera, repetidas, versiones)
cartera <- cartera[order(cartera$fecha_emision, cartera$factura), ]
rownames(cartera) <- NULL

arrow::write_parquet(cartera, "datos/cap06/cartera_2026_t1.parquet")

# 2. Recaudos del primer trimestre (ejercicio) ------------------------------
sanas <- cartera[cartera$pagada & !is.na(cartera$fecha_pago) &
                   cartera$fecha_pago >= cartera$fecha_emision &
                   cartera$saldo == 0 & !duplicated(cartera$factura) &
                   !duplicated(cartera$factura, fromLast = TRUE), ]
m <- nrow(sanas)
medios <- c("Transferencia", "Transferencia", "PSE", "Cheque", "Efectivo")

recaudos <- data.frame(
  recaudo         = sprintf("RC-%04d", seq_len(m)),
  factura         = sanas$factura,
  fecha_recaudo   = sanas$fecha_pago,
  valor_recaudado = sanas$valor_factura,
  medio_pago      = sample(medios, m, replace = TRUE)
)

libres <- seq_len(m)

# Problema: medio de pago fuera del catálogo o escrito de otra forma
recaudos$medio_pago[tomar(2)] <- "transferencia"
recaudos$medio_pago[tomar(1)] <- "TRANSFERENCIA "
recaudos$medio_pago[tomar(2)] <- "Consignacion"
recaudos$medio_pago[tomar(2)] <- NA

# Problema: recaudo de una factura que no existe en la cartera
f <- tomar(3)
recaudos$factura[f] <- c("FV-29901", "FV-29902", "FV-29903")

# Problema: recaudo anterior a la emisión de la factura
f <- tomar(2)
recaudos$fecha_recaudo[f] <- recaudos$fecha_recaudo[f] - 60

# Problema: valor recaudado cero o negativo
f <- tomar(2)
recaudos$valor_recaudado[f] <- c(0, -150000)

# Problema: una factura cobrada dos veces (la suma supera el valor)
f <- tomar(2)
dobles <- recaudos[f, ]
dobles$recaudo <- sprintf("RC-%04d", m + seq_along(f))
dobles$fecha_recaudo <- dobles$fecha_recaudo + 3

# Problema: el mismo recaudo cargado dos veces
copias <- recaudos[tomar(2), ]

recaudos <- rbind(recaudos, dobles, copias)
recaudos <- recaudos[order(recaudos$fecha_recaudo, recaudos$recaudo), ]
rownames(recaudos) <- NULL

arrow::write_parquet(recaudos, "datos/cap06/recaudos_2026_t1.parquet")

message("Datos del capítulo 6 generados en datos/cap06/ (",
        nrow(cartera), " facturas, ", nrow(recaudos), " recaudos)")
