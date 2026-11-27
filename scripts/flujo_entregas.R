# Flujo de las entregas (capítulo 13): de los CSV mensuales a los indicadores.
#
# Uso desde R, en la carpeta raíz del proyecto:
#   source("scripts/flujo_entregas.R")
#   resultado <- ejecutar_flujo(rutas, pasos_entregas)
#
# Uso desde la terminal (ejecuta el flujo completo en una sesión limpia):
#   Rscript scripts/flujo_entregas.R datos/cap13/entregas
#
# Cada paso es una función que recibe el resultado del paso anterior.

# Paso 1. Leer -----------------------------------------------------------------

#' Lee cada archivo como texto, sin adivinar tipos, y conserva su nombre.
#' @return Una lista de tablas, una por archivo.
leer_crudo <- function(rutas) {
  stopifnot("no hay archivos para leer" = length(rutas) > 0)
  names(rutas) <- basename(rutas)
  purrr::map(rutas, \(ruta) {
    readr::read_csv(ruta, col_types = readr::cols(.default = "c"))
  })
}

# Paso 2. Armonizar --------------------------------------------------------------

#' Lleva cada archivo al mismo esquema y convierte los tipos.
#' Resuelve los cambios conocidos: tiempo en minutos y fechas día/mes/año.
armonizar <- function(tablas) {
  una <- function(d) {
    if ("tiempo_entrega_min" %in% names(d)) {
      d$tiempo_entrega_h <- as.character(as.numeric(d$tiempo_entrega_min) / 60)
      d$tiempo_entrega_min <- NULL
    }
    iso <- grepl("^\\d{4}-\\d{2}-\\d{2}$", d$fecha)
    fecha <- as.Date(rep(NA_character_, nrow(d)))
    fecha[iso] <- as.Date(d$fecha[iso], format = "%Y-%m-%d")
    fecha[!iso] <- as.Date(d$fecha[!iso], format = "%d/%m/%Y")
    d$fecha <- fecha
    d
  }
  numericas <- c("distancia_km", "tiempo_entrega_h", "unidades", "valor_pedido")
  purrr::map(tablas, una) |>
    purrr::list_rbind(names_to = "archivo") |>
    dplyr::mutate(
      dplyr::across(dplyr::all_of(numericas), as.numeric),
      calificacion = as.integer(calificacion),
      devuelto = as.logical(devuelto)
    )
}

# Paso 3. Validar ---------------------------------------------------------------

#' Detiene el flujo si los datos no cumplen las reglas que bloquean.
validar <- function(d) {
  esperadas <- c(
    "pedido",
    "fecha",
    "sucursal",
    "canal",
    "distancia_km",
    "tiempo_entrega_h",
    "unidades",
    "valor_pedido",
    "calificacion",
    "devuelto"
  )
  problemas <- c(
    if (length(setdiff(esperadas, names(d))) > 0) {
      paste(
        "faltan columnas:",
        paste(setdiff(esperadas, names(d)), collapse = ", ")
      )
    },
    if (anyNA(d$fecha)) {
      sprintf(
        "%d fechas sin leer en %s",
        sum(is.na(d$fecha)),
        paste(unique(d$archivo[is.na(d$fecha)]), collapse = ", ")
      )
    },
    if (anyDuplicated(d$pedido) > 0) {
      sprintf("%d pedidos repetidos", sum(duplicated(d$pedido)))
    },
    if (any(d$tiempo_entrega_h > 72, na.rm = TRUE)) {
      sprintf(
        "%d tiempos de entrega de más de 72 horas",
        sum(d$tiempo_entrega_h > 72, na.rm = TRUE)
      )
    },
    if (any(is.na(d$tiempo_entrega_h) & d$canal != "retiro")) {
      sprintf(
        "%d entregas a domicilio sin tiempo de entrega",
        sum(is.na(d$tiempo_entrega_h) & d$canal != "retiro")
      )
    }
  )
  if (length(problemas) > 0) {
    stop(
      "los datos no pasan la validación:\n- ",
      paste(problemas, collapse = "\n- "),
      call. = FALSE
    )
  }
  d
}

# Paso 4. Resumir ---------------------------------------------------------------

#' Indicadores mensuales por sucursal.
resumir <- function(d) {
  tasa <- function(parte, total) {
    round(100 * parte / ifelse(total == 0, NA, total), 1)
  }
  d |>
    dplyr::filter(canal != "retiro") |>
    dplyr::mutate(mes = format(fecha, "%Y-%m")) |>
    dplyr::summarise(
      pedidos = dplyr::n(),
      mediana_horas = stats::median(tiempo_entrega_h),
      pct_tardias = tasa(sum(tiempo_entrega_h > 20), pedidos),
      pct_devueltos = tasa(sum(devuelto), pedidos),
      .by = c(mes, sucursal)
    ) |>
    dplyr::arrange(mes, sucursal)
}

# Paso 5. Guardar ---------------------------------------------------------------

#' Guarda los indicadores y los devuelve sin cambios.
guardar <- function(indicadores, ruta = "datos/cap13/salida/indicadores.csv") {
  dir.create(dirname(ruta), showWarnings = FALSE, recursive = TRUE)
  readr::write_csv(indicadores, ruta)
  indicadores
}

# El flujo ----------------------------------------------------------------------

pasos_entregas <- list(
  leer = leer_crudo,
  armonizar = armonizar,
  validar = validar,
  resumir = resumir,
  guardar = guardar
)

#' Ejecuta los pasos en orden: la salida de cada uno es la entrada del siguiente.
#' Registra cuánto tardó cada paso y, si uno falla, dice cuál.
ejecutar_flujo <- function(
  entrada,
  pasos,
  bitacora = "datos/cap13/salida/bitacora.log"
) {
  dir.create(dirname(bitacora), showWarnings = FALSE, recursive = TRUE)
  anotar <- function(...) {
    linea <- sprintf(
      "%s  %s",
      format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      sprintf(...)
    )
    cat(linea, "\n", file = bitacora, append = TRUE, sep = "")
    message(linea)
  }
  anotar("inicio del flujo: %d pasos", length(pasos))
  datos <- entrada
  for (nombre in names(pasos)) {
    inicio <- Sys.time()
    datos <- tryCatch(
      pasos[[nombre]](datos),
      error = function(e) {
        anotar("FALLÓ el paso '%s'", nombre)
        stop(
          sprintf("el paso '%s' falló: %s", nombre, conditionMessage(e)),
          call. = FALSE
        )
      }
    )
    filas <- if (is.data.frame(datos)) {
      nrow(datos)
    } else {
      sum(purrr::map_int(datos, nrow))
    }
    anotar(
      "%-10s %6d filas  %5.2f s",
      nombre,
      filas,
      as.numeric(difftime(Sys.time(), inicio, units = "secs"))
    )
  }
  anotar("fin del flujo")
  datos
}

# Al ejecutarse desde la terminal con Rscript, corre el flujo completo.
if (sys.nframe() == 0) {
  carpeta <- commandArgs(trailingOnly = TRUE)
  carpeta <- if (length(carpeta) == 0) "datos/cap13/entregas" else carpeta
  rutas <- list.files(carpeta, pattern = "\\.csv$", full.names = TRUE)
  invisible(ejecutar_flujo(rutas, pasos_entregas))
}
