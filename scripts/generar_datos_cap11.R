# Genera los datos sintéticos del capítulo 11 (Explorar los datos).
#
# Uso, desde la carpeta raíz del proyecto:
#   Rscript scripts/generar_datos_cap11.R
#
# Produce:
#   datos/cap11/entregas_2026_t1.parquet
#
# Pedidos entregados por la red de distribución en el primer trimestre de 2026.
# Los datos traen patrones sembrados para la exploración:
#   - S03 (Cali) usa dos medios de transporte: mensajería en moto el mismo día y
#     transportadora al día siguiente. Su tiempo de entrega es bimodal.
#   - S07 (Pasto) apenas empezó el servicio a domicilio: tiene muy pocos pedidos.
#   - Faltantes de tres clases: estructurales (el retiro en tienda no tiene
#     distancia ni tiempo de entrega), al azar (algunos valores del pedido) e
#     informativos (la calificación falta más cuando la entrega fue tardía).
#   - El valor del pedido tiene una cola larga: unos pocos pedidos corporativos
#     valen decenas de veces más que el resto.
#   - Menos pedidos los domingos.

set.seed(2031)
dir.create("datos/cap11", showWarnings = FALSE, recursive = TRUE)

n <- 2400
sucursales <- sprintf("S%02d", 1:8)
peso <- c(1.3, 1.2, 1.1, 1, 0.9, 0.8, 0.03, 0.9)

dias <- seq(as.Date("2026-01-02"), as.Date("2026-03-31"), by = "day")
peso_dia <- ifelse(format(dias, "%u") == "7", 0.35, 1)

pedidos <- data.frame(
  pedido = sprintf("PD-%05d", seq_len(n)),
  fecha = sort(sample(dias, n, replace = TRUE, prob = peso_dia)),
  sucursal = sample(sucursales, n, replace = TRUE, prob = peso),
  canal = sample(
    c("domicilio", "web", "retiro"),
    n,
    replace = TRUE,
    prob = c(0.45, 0.35, 0.20)
  )
)

# Distancia: no aplica al retiro en tienda (faltante estructural)
pedidos$distancia_km <- round(rlnorm(n, log(6), 0.55), 1)
pedidos$distancia_km[pedidos$canal == "retiro"] <- NA

# Tiempo de entrega en horas: crece con la distancia; S03 es bimodal
base <- 2 + 0.55 * pedidos$distancia_km + rgamma(n, shape = 2, rate = 0.4)
en_s03 <- pedidos$sucursal == "S03"
transportadora <- en_s03 & runif(n) < 0.45
base[en_s03 & !transportadora] <- rnorm(sum(en_s03 & !transportadora), 4, 1.2)
base[transportadora] <- rnorm(sum(transportadora), 26, 3.5)
pedidos$tiempo_entrega_h <- round(pmax(base, 0.5), 1)
pedidos$tiempo_entrega_h[pedidos$canal == "retiro"] <- NA

# Valor del pedido: cola larga y unos pocos pedidos corporativos
pedidos$unidades <- 1 + rpois(n, 6)
pedidos$valor_pedido <- round(rlnorm(n, log(180000), 0.7), -2)
corporativos <- sample(n, 6)
pedidos$valor_pedido[corporativos] <- round(runif(6, 12e6, 30e6), -3)
pedidos$unidades[corporativos] <- sample(300:900, 6)
pedidos$valor_pedido[sample(n, 22)] <- NA # faltantes al azar

# Calificación de 1 a 5: baja cuando la entrega es tardía
tardia <- !is.na(pedidos$tiempo_entrega_h) & pedidos$tiempo_entrega_h > 20
nota <- 4.4 - 1.6 * tardia + rnorm(n, 0, 0.8)
pedidos$calificacion <- as.integer(pmin(pmax(round(nota), 1), 5))
# Faltante informativo: quien recibió tarde responde menos la encuesta
prob_na <- ifelse(tardia, 0.50, 0.15)
pedidos$calificacion[runif(n) < prob_na] <- NA

pedidos$devuelto <- runif(n) < ifelse(tardia, 0.10, 0.04)

arrow::write_parquet(pedidos, "datos/cap11/entregas_2026_t1.parquet")
message("Datos del capítulo 11 generados en datos/cap11/")
