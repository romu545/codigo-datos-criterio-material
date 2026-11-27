# Reglas de calidad de la cartera (capítulo 6), reunidas para reutilizarlas.
#
# Uso, desde un script o un capítulo:
#   source("scripts/auditoria_cartera.R")
#   reglas  <- reglas_cartera(clientes)
#   reporte <- auditar(cartera, reglas)
#
# Cada regla dice qué filas CUMPLEN; las reglas de validez dejan pasar los
# faltantes de forma explícita, porque de ellos se encargan las de completitud.

reglas_cartera <- function(
  clientes,
  inicio = as.Date("2026-01-01"),
  corte = as.Date("2026-03-31")
) {
  ciudades_validas <- sort(unique(clientes$ciudad))

  dplyr::tribble(
    ~regla                 , ~dimension      , ~severidad , ~cumple                                                                ,
    "nit_presente"         , "Completitud"   , "bloquea"  , \(d) !is.na(d$nit)                                                     ,
    "ciudad_presente"      , "Completitud"   , "advierte" , \(d) !is.na(d$ciudad)                                                  ,
    "factura_unica"        , "Unicidad"      , "bloquea"  , \(d) !(duplicated(d$factura) | duplicated(d$factura, fromLast = TRUE)) ,
    "valor_positivo"       , "Validez"       , "bloquea"  , \(d) d$valor_factura > 0                                               ,
    "calificacion_1_a_5"   , "Validez"       , "advierte" , \(d) is.na(d$calificacion) | d$calificacion %in% 1:5                   ,
    "emision_en_periodo"   , "Validez"       , "bloquea"  , \(d) d$fecha_emision >= inicio & d$fecha_emision <= corte              ,
    "nit_10_digitos"       , "Validez"       , "bloquea"  , \(d) is.na(d$nit) | grepl("^[0-9]{10}$", d$nit)                        ,
    "ciudad_en_catalogo"   , "Validez"       , "advierte" , \(d) is.na(d$ciudad) | d$ciudad %in% ciudades_validas                  ,
    "pago_despues_emision" , "Consistencia"  , "bloquea"  , \(d) is.na(d$fecha_pago) | d$fecha_pago >= d$fecha_emision             ,
    "pagada_con_fecha"     , "Consistencia"  , "bloquea"  , \(d) d$pagada == !is.na(d$fecha_pago)                                  ,
    "pagada_sin_saldo"     , "Consistencia"  , "bloquea"  , \(d) !d$pagada | d$saldo == 0                                          ,
    "saldo_hasta_valor"    , "Consistencia"  , "bloquea"  , \(d) d$saldo <= d$valor_factura                                        ,
    "nit_en_clientes"      , "Integridad"    , "bloquea"  , \(d) is.na(d$nit) | d$nit %in% clientes$nit                            ,
    "valor_plausible"      , "Plausibilidad" , "advierte" , \(d) d$valor_factura <= 50e6
  )
}

# Devuelve el reporte: cuántas filas falla cada regla.
auditar <- function(datos, reglas) {
  marcas <- vapply(
    reglas$cumple,
    \(cumple) !cumple(datos),
    logical(nrow(datos))
  )
  marcas <- matrix(
    marcas,
    nrow = nrow(datos),
    dimnames = list(NULL, reglas$regla)
  )
  stopifnot(!anyNA(marcas))
  reporte <- reglas[, c("regla", "dimension", "severidad")]
  reporte$filas <- colSums(marcas)
  reporte
}
