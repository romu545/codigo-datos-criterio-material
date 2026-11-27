# Datos del capítulo 7: Transformación y limpieza I

Datos **sintéticos** de la misma red regional de distribución. Las sucursales son las del catálogo del capítulo 4 y los NIT, los de la tabla `clientes` de `datos/cap04/operaciones.duckdb`.

| Archivo | Formato | Para qué sirve |
|---|---|---|
| `ventas_2026_t1.parquet` | Parquet, 6.000 filas | Ejemplos 7.1 a 7.4: elegir, filtrar, ordenar, crear columnas, resumir y unir |
| `productos.csv` | CSV, 13 filas | Ejemplo 7.4: catálogo de productos; el producto `P07` está repetido a propósito |
| `sucursales.csv` | CSV, 8 filas | Ejemplo 7.4: ciudad y región de cada sucursal |
| `metas_2026_ancho.csv` | CSV, formato ancho | Ejemplos 7.5 y 7.6: metas mensuales con una columna por mes y la ciudad y el departamento en una sola columna |
| `pedidos_web.csv` | CSV, 250 filas | Ejemplo 7.6 y Ejercicio 7.1: varios productos en una celda y contactos con nombre y correo juntos |
| `ventas_grande.parquet` | Parquet, 10 millones de filas, unos 120 MB | Ejemplo 7.7 (volumen). **No está en el repositorio** |

Todos se generan con `Rscript scripts/generar_datos_cap07.R`, desde la carpeta raíz del proyecto.

Si reportas un error en los datos o en el libro, hazlo en el [repositorio del libro](https://github.com/romu545/codigo-datos-criterio/issues).
