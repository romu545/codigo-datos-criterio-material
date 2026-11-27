# Datos del capítulo 9: Transformación y limpieza III

Datos **sintéticos** de la misma red regional de distribución. Los indicadores de ventas salen de `datos/cap07/ventas_2026_t1.parquet`.

| Archivo | Formato | Para qué sirve |
|---|---|---|
| `indicadores/ventas_mes.csv`, `recaudos_mes.csv`, `visitas_mes.csv`, `devoluciones_mes.csv` | CSV, unas 24 filas cada uno | Ejemplo 9.2: un indicador mensual por sucursal en cada archivo. `devoluciones_mes.csv` trae la fila de `S04` en febrero repetida y a `visitas_mes.csv` le falta `S07` en marzo, a propósito |
| `precios_historial.csv` | CSV, 20 filas | Ejemplo 9.3: precio de cada producto con la fecha desde la que rige; ocho productos subieron de precio en febrero o marzo |
| `tramos_comision.csv` | CSV, 4 filas | Ejemplo 9.3: tramos de comisión según las ventas del mes; el último tramo no tiene techo |
| `conteos/conteo_S01.csv` a `conteo_S08.csv` | CSV, 12 filas cada uno | Ejemplo 9.8: conteo físico de inventario por sucursal. `S04` tiene `N/D` en una fila y `S07` llama `cantidad` a la columna `unidades_contadas`, a propósito |

Se generan con `Rscript scripts/generar_datos_cap09.R`, desde la carpeta raíz del proyecto, después de generar los datos del capítulo 7.

Si reportas un error en los datos o en el libro, hazlo en el [repositorio del libro](https://github.com/romu545/codigo-datos-criterio/issues).
