# Datos del capítulo 6: Tipos de datos y calidad

Datos **sintéticos** de la misma red regional de distribución de los capítulos 3 a 5. No corresponden a personas ni a empresas reales. Los NIT coinciden con la tabla `clientes` de `datos/cap04/operaciones.duckdb`.

| Archivo | Formato | Para qué sirve |
|---|---|---|
| `cartera_2026_t1.parquet` | Parquet, 406 filas | Ejemplos 6.1 a 6.7: la cartera del primer trimestre de 2026, con la estructura que deja el contrato del capítulo 5 y problemas de calidad sembrados a propósito (filas y facturas repetidas, NIT sin el cero inicial o inexistentes, valores negativos, calificaciones fuera de escala, un año mal digitado, ciudades escritas de varias formas e inconsistencias entre pago, fecha de pago y saldo) |
| `clientes.parquet` | Parquet, 200 filas | Catálogo de clientes para la integridad referencial y el catálogo de ciudades |
| `recaudos_2026_t1.parquet` | Parquet, 183 filas | Ejercicio 6.1: pagos recibidos, con sus propios problemas de calidad |

Los tres archivos se generan con `Rscript scripts/generar_datos_cap06.R`, desde la carpeta raíz del proyecto. El script marca cada problema sembrado con un comentario `Problema:`; si quieres resolver el ejercicio sin pistas, no lo leas antes.

## Archivos que se generan al trabajar el capítulo

- `cartera_2026_t1_auditada.parquet` (Ejemplo 6.7): la cartera con la columna `problemas`, que muestra el resultado de la auditoría. El capítulo 8 vuelve a partir de la cartera cruda y la limpia.

Si reportas un error en los datos o en el libro, hazlo en el [repositorio del libro](https://github.com/romu545/codigo-datos-criterio/issues).
