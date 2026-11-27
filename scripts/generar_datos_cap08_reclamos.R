# Genera los reclamos del capítulo 8 (Ejemplo guiado 8.8: clasificar texto
# libre con un modelo de lenguaje).
#
# Uso, desde la carpeta raíz del proyecto:
#   Rscript scripts/generar_datos_cap08_reclamos.R
#
# Produce, en datos/cap08/:
#   reclamos_2026_t1.csv        Reclamos de clientes en texto libre. Algunos
#                               traen datos personales (celular, correo,
#                               cédula) que hay que ocultar antes de enviarlos
#                               a un servicio externo.
#   reclamos_revision.csv       Muestra de 150 reclamos clasificados por una
#                               persona: la referencia para medir al modelo.
#   reclamos_clasificados.csv   Categoría propuesta por un modelo de lenguaje
#                               para cada reclamo. Las respuestas son
#                               SIMULADAS, para que el ejemplo sea
#                               reproducible y no dependa de una cuenta ni de
#                               una versión de modelo. Los errores imitan los
#                               habituales: casos con dos problemas y frases
#                               irónicas.

set.seed(2608)
dir.create("datos/cap08", showWarnings = FALSE, recursive = TRUE)

n <- 400
categorias <- c(
  "entrega_tardia",
  "producto_danado",
  "pedido_incompleto",
  "cobro",
  "atencion",
  "otro"
)
prob <- c(0.28, 0.20, 0.18, 0.14, 0.12, 0.08)

productos <- c(
  "detergente",
  "jabón de barra",
  "aceite",
  "arroz",
  "café",
  "papel higiénico",
  "suavizante"
)
uno <- function(x) sample(x, 1)

plantillas <- list(
  entrega_tardia = c(
    "El pedido llegó {d} días después de lo prometido.",
    "Llevamos {d} días esperando el pedido y nada que llega.",
    "Me dijeron que llegaba el martes y llegó el {dia}.",
    "otra vez tarde, ya van {d} días de retraso",
    "El domiciliario nunca llegó a la hora acordada, tocó esperar toda la tarde.",
    "Necesitaba el {p} para el fin de semana y lo entregaron el lunes."
  ),
  ironia = c(
    "Excelente servicio, solo tuve que esperar {d} días.",
    "Felicitaciones, récord de lentitud: {d} días para un pedido.",
    "Qué maravilla, el pedido de la semana pasada llegó hoy.",
    "Muy puntuales como siempre... {d} días tarde."
  ),
  producto_danado = c(
    "El {p} llegó con el empaque roto.",
    "Las cajas de {p} venían mojadas y no se pueden vender.",
    "Llegó el {p} vencido.",
    "{k} unidades de {p} llegaron aplastadas.",
    "el {p} venia abierto y regado en la caja"
  ),
  pedido_incompleto = c(
    "Pedí {k2} cajas de {p} y llegaron {k}.",
    "Faltó el {p} en el pedido.",
    "El pedido llegó sin el {p} que estaba en la factura.",
    "Nos mandaron {k} unidades de {p} cuando pedimos {k2}."
  ),
  mixto = c(
    "El pedido llegó {d} días tarde y además faltaron {k} cajas de {p}.",
    "Llegó tarde y sin el {p}.",
    "Después de {d} días de espera, llegó incompleto: faltó el {p}."
  ),
  cobro = c(
    "En la factura me cobraron el {p} dos veces.",
    "No me aplicaron el descuento acordado.",
    "Me cobraron un valor distinto al de la cotización.",
    "Pagué por transferencia y la factura sigue apareciendo pendiente.",
    "cobro doble en la factura de este mes"
  ),
  atencion = c(
    "Nadie contesta en la línea de servicio.",
    "El asesor fue grosero cuando llamé a preguntar por el pedido.",
    "Escribí tres veces al correo de soporte y no he recibido respuesta.",
    "Me pasaron con cuatro personas distintas y nadie me resolvió."
  ),
  otro = c(
    "¿Pueden agregar el {p} integral al catálogo?",
    "Quiero cambiar la dirección de entrega de mis próximos pedidos.",
    "Solicito el certificado de retención del año pasado.",
    "¿Tienen sucursal en Montería?"
  )
)

rellenar <- function(texto) {
  k <- sample(1:4, 1)
  reemplazos <- c(
    "{d}" = as.character(sample(3:12, 1)),
    "{dia}" = uno(c("jueves", "viernes", "sábado")),
    "{p}" = uno(productos),
    "{k}" = as.character(k),
    "{k2}" = as.character(k + sample(2:6, 1))
  )
  for (marca in names(reemplazos)) {
    texto <- gsub(marca, reemplazos[[marca]], texto, fixed = TRUE)
  }
  texto
}

categoria <- sample(categorias, n, replace = TRUE, prob = prob)
tipo <- categoria
tipo[categoria == "entrega_tardia" & runif(n) < 0.25] <- "ironia"
tipo[categoria == "pedido_incompleto" & runif(n) < 0.40] <- "mixto"
texto <- vapply(tipo, \(t) rellenar(uno(plantillas[[t]])), character(1))

# Datos personales en algunos textos
celular <- \() paste0("3", paste(sample(0:9, 9, replace = TRUE), collapse = ""))
correo <- \() {
  paste0(
    uno(c("laura", "jorge", "marta", "luis", "ana")),
    ".",
    uno(c("gomez", "ruiz", "pena", "gil", "rios")),
    "@",
    uno(c("correo.co", "gmail.com", "distrigil.co"))
  )
}
cedula <- \() {
  formatC(
    10e6 + sample.int(1089e6, 1),
    format = "d",
    big.mark = ".",
    decimal.mark = ","
  )
}
anexo <- sample(
  c("", "celular", "correo", "cedula"),
  n,
  replace = TRUE,
  prob = c(0.85, 0.07, 0.05, 0.03)
)
texto <- ifelse(
  anexo == "celular",
  paste(texto, "Mi celular es", vapply(seq_len(n), \(i) celular(), "")),
  texto
)
texto <- ifelse(
  anexo == "correo",
  paste(texto, "Escríbanme a", vapply(seq_len(n), \(i) correo(), "")),
  texto
)
texto <- ifelse(
  anexo == "cedula",
  paste0(texto, " Cédula ", vapply(seq_len(n), \(i) cedula(), ""), "."),
  texto
)

reclamos <- data.frame(
  reclamo = sprintf("RC-%04d", seq_len(n)),
  fecha = sort(sample(
    seq(as.Date("2026-01-02"), as.Date("2026-03-31"), by = "day"),
    n,
    replace = TRUE
  )),
  sucursal = sample(sprintf("S%02d", 1:8), n, replace = TRUE),
  texto = texto
)

# Revisión humana: una muestra de 150 reclamos
muestra <- sort(sample(seq_len(n), 150))
revision <- data.frame(
  reclamo = reclamos$reclamo[muestra],
  categoria_revisor = categoria[muestra]
)

# Respuestas simuladas del modelo
otra <- \(actual) uno(setdiff(categorias, actual))
modelo <- categoria
for (i in seq_len(n)) {
  if (tipo[i] == "mixto" && runif(1) < 0.65) {
    modelo[i] <- "entrega_tardia"
  } else if (tipo[i] == "ironia" && runif(1) < 0.70) {
    modelo[i] <- uno(c("atencion", "otro"))
  } else if (runif(1) < 0.03) {
    modelo[i] <- otra(categoria[i])
  }
}
clasificados <- data.frame(
  reclamo = reclamos$reclamo,
  categoria_modelo = modelo,
  version_prompt = "v1",
  consultado = "2026-04-02"
)

write.csv(
  reclamos,
  "datos/cap08/reclamos_2026_t1.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  revision,
  "datos/cap08/reclamos_revision.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  clasificados,
  "datos/cap08/reclamos_clasificados.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

message("Reclamos: ", n, "; muestra revisada: ", nrow(revision))
