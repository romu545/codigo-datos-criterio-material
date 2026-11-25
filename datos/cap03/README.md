# Datos del capítulo 3: Importación de datos I

Datos **sintéticos** de una red regional de distribución en Colombia (2024-2026). No corresponden a personas ni a empresas reales. Se generan con `scripts/generar_datos_cap03.py` y una semilla fija, por lo que siempre son los mismos.

| Archivo | Formato | Para qué sirve |
|---|---|---|
| `ventas_2026_01.csv` | CSV con `;`, coma decimal y `Latin-1` (5.000 filas) | Ejemplo 3.1: delimitadores, codificación, ceros a la izquierda y proyección de columnas |
| `lotes_mensuales/recaudos_*.csv` | CSV (UTF-8) | Ejemplo 3.2 y Ejercicio 3.1: lectura de varios archivos y deriva de esquema (`vlr_total` frente a `valor_total`) |
| `lotes_mensuales/borrador_notas.csv` | CSV | Archivo distractor que no debe entrar al análisis |
| `chat_soporte_sucursales.txt` | Texto UTF-8 con formato de chat exportado de WhatsApp | Ejemplo 3.3: extraer columnas con expresiones regulares de grupos con nombre |

## Cómo generar los datos

Desde la raíz del repositorio de materiales (requiere [uv](https://docs.astral.sh/uv/)):

```bash
uv run scripts/generar_datos_cap03.py            # archivos pequeños
uv run scripts/generar_datos_cap03.py --grande   # además, el CSV grande
uv run scripts/generar_datos_cap03.py --solo-grande
```

`uv run` instala automáticamente las dependencias que declara el propio script.

## Notas

- Los identificadores (`codigo_dane`, `nit_cliente`, `nit`) son **texto con ceros a la izquierda**: es intencional.
- Los NIT de `ventas_2026_01.csv`, de los recaudos, de la respuesta JSON y de la tabla `clientes` salen del mismo conjunto de clientes, y los `codigo_dane` coinciden con los de `catalogo_sucursales.xlsx`. Así se pueden combinar con las fuentes del capítulo 4 (`datos/cap04/`) en el Ejercicio 4.2.
- `datos/cap04/operaciones.duckdb` se crea con un formato de almacenamiento compatible con versiones 1.x de DuckDB, para que también lo abra el paquete `duckdb` de R aunque esté en una versión anterior a la de Python.
- Si reportas un error en los datos o en el libro, hazlo en el [repositorio del libro](https://github.com/romu545/codigo-datos-criterio/issues).
