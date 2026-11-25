# Datos del capítulo 8: Transformación y limpieza II

Datos **sintéticos** de la misma red regional de distribución.

| Archivo | Formato | Para qué sirve |
|---|---|---|
| `clientes_crm.csv` | CSV, 255 filas | Ejemplos 8.1 a 8.4: exportación del sistema de gestión de clientes, con nombres, razones sociales, ciudades, NIT, teléfonos y correos escritos de varias formas, y clientes registrados más de una vez |

Se genera con `Rscript scripts/generar_datos_cap08.R`, desde la carpeta raíz del proyecto. La limpieza completa del capítulo (Ejemplo 8.7) usa la cartera y los clientes de `datos/cap06/`, y las reglas de calidad de `scripts/auditoria_cartera.R` y `scripts/auditoria_cartera.py`.

## Archivos que se generan al trabajar el capítulo

- `equivalencias_ciudad.csv` (Ejemplo 8.3): la tabla de equivalencias de las ciudades.
- `cartera_2026_t1_limpia.parquet`, `cartera_2026_t1_cuarentena.parquet` y `bitacora_limpieza_cartera.csv` (Ejemplo 8.7).

Si reportas un error en los datos o en el libro, hazlo en el [repositorio del libro](https://github.com/romu545/codigo-datos-criterio/issues).
