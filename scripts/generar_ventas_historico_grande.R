# Genera datos/cap04/ventas_historico_grande.csv para el Ejercicio 4.1
# (CSV frente a Parquet). Unos 2,5 millones de filas y alrededor de 130 MB.
#
# El archivo se escribe con DuckDB, sin pasar por la memoria de R. Los valores
# salen de hash(), no de números aleatorios, así que con la misma versión de
# DuckDB el archivo es idéntico cada vez que se genera.
#
# Uso, desde la carpeta raíz de los materiales:
#   Rscript scripts/generar_ventas_historico_grande.R

use("DBI", c("dbConnect", "dbExecute", "dbDisconnect"))
use("duckdb", "duckdb")

n_filas <- 2500000
destino <- "datos/cap04/ventas_historico_grande.csv"

con <- dbConnect(duckdb())

dbExecute(con, sprintf("
  COPY (
    SELECT
      i + 1 AS id_venta,
      DATE '2024-01-01' + CAST(hash(i, 'fecha') %% 731 AS INTEGER) AS fecha,
      s.codigo_dane,
      s.ciudad,
      lpad(CAST(hash(i, 'nit') %% 5000 * 199999 AS VARCHAR), 10, '0') AS nit_cliente,
      round(50000 + (hash(i, 'valor') %% 245000000) / 100, 2) AS valor_venta
    FROM range(%d) AS r(i)
    JOIN (
      SELECT * FROM (VALUES
        (0, '11001', 'Bogotá'),    (1, '05001', 'Medellín'),
        (2, '76001', 'Cali'),      (3, '08001', 'Barranquilla'),
        (4, '13001', 'Cartagena'), (5, '54001', 'Cúcuta'),
        (6, '52001', 'Pasto'),     (7, '47001', 'Santa Marta')
      ) AS t(k, codigo_dane, ciudad)
    ) AS s ON s.k = hash(i, 'sucursal') %% 8
    ORDER BY id_venta
  ) TO '%s' (HEADER, DELIMITER ',')
", n_filas, destino))

dbDisconnect(con)
message("Archivo creado: ", destino, " (",
        round(file.size(destino) / 1024^2, 1), " MB)")
