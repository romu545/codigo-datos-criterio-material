# Funciones de inventario (capítulos 9 y 12).
#
# Uso, desde la carpeta raíz del proyecto:
#   source("scripts/inventario.R")
#   pol <- nueva_politica(reorden = 80)
#   simular_con(demanda, pol)

#' Crea una política de inventario validada.
#'
#' @param inicial Unidades al empezar.
#' @param reorden Se pide un lote cuando el inventario baja de este nivel.
#' @param lote Unidades de cada pedido.
#' @param espera Días entre el pedido y la llegada.
#' @return Una lista de clase "politica_inventario".
nueva_politica <- function(
  inicial = 120,
  reorden = 50,
  lote = 100,
  espera = 5
) {
  valores <- c(
    inicial = inicial,
    reorden = reorden,
    lote = lote,
    espera = espera
  )
  stopifnot(
    "los parámetros deben ser números de un solo valor" = is.numeric(valores) &&
      length(valores) == 4,
    "ningún parámetro puede ser negativo" = all(valores >= 0),
    "el lote debe ser mayor que cero" = lote > 0,
    "la espera debe ser de al menos un día" = espera >= 1
  )
  structure(as.list(valores), class = "politica_inventario")
}

#' Muestra una política en una línea.
print.politica_inventario <- function(x, ...) {
  cat(sprintf(
    "Política: inicia con %g, pide %g cuando baja de %g, llega en %g días\n",
    x$inicial,
    x$lote,
    x$reorden,
    x$espera
  ))
  invisible(x)
}

#' Simula el inventario día a día (capítulo 9).
#'
#' @param demanda Vector con las unidades pedidas cada día.
#' @return Una tabla con el inventario al final de cada día y las ventas perdidas.
simular_inventario <- function(
  demanda,
  inicial = 120,
  reorden = 50,
  lote = 100,
  espera = 5
) {
  n <- length(demanda)
  inventario <- numeric(n)
  perdidas <- numeric(n)
  disponible <- inicial
  llegada <- NA

  for (t in seq_len(n)) {
    if (!is.na(llegada) && t == llegada) {
      disponible <- disponible + lote
      llegada <- NA
    }
    vendido <- min(demanda[t], disponible)
    perdidas[t] <- demanda[t] - vendido
    disponible <- disponible - vendido
    if (disponible < reorden && is.na(llegada)) {
      llegada <- t + espera
    }
    inventario[t] <- disponible
  }
  data.frame(inventario, perdidas)
}

#' Simula con una política creada con nueva_politica().
simular_con <- function(demanda, politica) {
  stopifnot(
    "politica debe crearse con nueva_politica()" = inherits(
      politica,
      "politica_inventario"
    )
  )
  do.call(simular_inventario, c(list(demanda), unclass(politica)))
}
