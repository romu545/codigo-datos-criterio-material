# Pruebas de las funciones del flujo de entregas (capítulos 13 y 17).
#
# Uso, desde la carpeta raíz del proyecto:
#   testthat::test_dir("tests/testthat")

library(testthat)
source(file.path("..", "..", "scripts", "flujo_entregas.R"), chdir = TRUE)

# Una tabla mínima, escrita a mano, con lo justo para probar cada caso.
tabla_minima <- function(...) {
  base <- data.frame(
    pedido = c("P1", "P2"),
    fecha = c("2026-03-01", "2026-03-02"),
    sucursal = c("S01", "S01"),
    canal = c("domicilio", "web"),
    distancia_km = c("5", "8"),
    tiempo_entrega_h = c("10", "30"),
    unidades = c("2", "3"),
    valor_pedido = c("100000", "200000"),
    calificacion = c("5", "2"),
    devuelto = c("FALSE", "TRUE")
  )
  cambios <- list(...)
  base[names(cambios)] <- cambios
  base
}

test_that("armonizar convierte los minutos a horas", {
  abril <- tabla_minima()
  abril$tiempo_entrega_min <- c("600", "1800")
  abril$tiempo_entrega_h <- NULL
  resultado <- armonizar(list(abril = abril))
  expect_equal(resultado$tiempo_entrega_h, c(10, 30))
  expect_false("tiempo_entrega_min" %in% names(resultado))
})

test_that("armonizar lee las fechas ISO y las de día/mes/año", {
  mezcla <- tabla_minima(fecha = c("2026-03-01", "02/03/2026"))
  resultado <- armonizar(list(mezcla = mezcla))
  expect_equal(resultado$fecha, as.Date(c("2026-03-01", "2026-03-02")))
})

test_that("validar detiene el flujo si hay fechas sin leer", {
  datos <- armonizar(list(
    malo = tabla_minima(fecha = c("2026-03-01", "marzo 2"))
  ))
  expect_error(validar(datos), "fechas sin leer en malo")
})

test_that("validar detiene el flujo si llegan minutos en la columna de horas", {
  datos <- armonizar(list(
    minutos = tabla_minima(tiempo_entrega_h = c("600", "1800"))
  ))
  expect_error(validar(datos), "más de 72 horas")
})

test_that("resumir calcula los porcentajes con los datos de la tabla", {
  indicadores <- resumir(validar(armonizar(list(t = tabla_minima()))))
  expect_equal(indicadores$pedidos, 2)
  expect_equal(indicadores$pct_tardias, 50)
  expect_equal(indicadores$pct_devueltos, 50)
})
