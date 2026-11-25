# Datos del capítulo 5: Importación de datos III

Datos **sintéticos** de la misma red regional de distribución de los capítulos 3 y 4. No corresponden a personas ni a empresas reales. Los NIT coinciden con la tabla `clientes` de `datos/cap04/operaciones.duckdb`.

| Archivo | Formato | Para qué sirve |
|---|---|---|
| `cartera_clientes_2026_02.csv` | CSV (`;`, UTF-8, coma decimal y punto de miles) | Ejemplos 5.1 a 5.6: nombres con tildes y símbolos, `N/A`, `SIN DATO` y `999` como faltantes, `SI`/`Sí`/`no` y `S`/`N` como booleanos, fechas día/mes/año, marca de tiempo en UTC, guion contable en el saldo y cuatro columnas vacías (una sin nombre) |
| `visitas_comerciales.xlsx` | Excel (hoja `Visitas`) | Ejercicio 5.1: booleano con `X` y vacío, guion como faltante, columnas vacías y fechas mezcladas (fechas de Excel y texto día/mes/año) |

Ambos archivos se generan con `Rscript scripts/generar_datos_cap05.R`, desde la carpeta raíz del proyecto.

## Archivos que se generan al trabajar el capítulo

- `cartera_2026_02.parquet` y `cartera_2026_02_duckdb.parquet` (Ejemplo 5.6).
- `visitas_comerciales.parquet` (Ejercicio 5.1).

Si reportas un error en los datos o en el libro, hazlo en el [repositorio del libro](https://github.com/romu545/codigo-datos-criterio/issues).
