# Datos del capítulo 4: Importación de datos II

Datos **sintéticos** de la misma red regional de distribución del capítulo 3. No corresponden a personas ni a empresas reales.

| Archivo | Formato | Para qué sirve |
|---|---|---|
| `catalogo_sucursales.xlsx` | Excel (hojas `Portada`, `Sucursales`, `Metas_2026`) | Ejemplos 4.1 y 4.3: en `Sucursales` los encabezados empiezan en la fila 4 |
| `ventas_2025_por_mes.xlsx` | Excel con una hoja por mes (`Ventas_Ene` a `Ventas_Dic`) y una hoja `Notas` | Ejemplos 4.2 y 4.4: consolidar hojas con la misma estructura y particionar en Parquet |
| `respuesta_api_trm.json` | JSON anidado | Ejemplo 4.5: forma típica de una respuesta de API |
| `operaciones.duckdb` | Base DuckDB (`facturas`, `clientes`) | Ejemplo 4.6: consultas con `JOIN` y filtros |
| `ventas_historico_grande.csv` | CSV (UTF-8), unos 2,5 millones de filas y ~130 MB | Ejercicio 4.1: comparación CSV frente a Parquet. **No está en el repositorio**: se genera con `Rscript scripts/generar_ventas_historico_grande.R` |

El proyecto integrador (Ejercicio 4.2) combina estos archivos con `datos/cap03/ventas_2026_01.csv`. Los NIT y los `codigo_dane` coinciden entre ambas carpetas.

## Archivos que se generan al trabajar el capítulo

No se guardan en el repositorio (ver `.gitignore`):

- `ventas_historico_grande.csv` y `ventas_historico.parquet` (Ejercicio 4.1).
- `ventas_2025_particionado/` y `ventas_2025_particionado_duckdb/` (Ejemplo 4.4).
- `copia_api.json` y `copia_api.parquet` (consumo de la API).
- `consolidado_cap04.parquet` (Ejercicio 4.2).

Si reportas un error en los datos o en el libro, hazlo en el [repositorio del libro](https://github.com/romu545/codigo-datos-criterio/issues).
