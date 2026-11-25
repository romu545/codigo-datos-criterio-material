# Código, datos y criterio: materiales

Datos y scripts que acompañan al libro [*Código, datos y criterio*](https://github.com/romu545/codigo-datos-criterio), un libro sobre análisis de datos con R y Python.

## Cómo descargarlos

- **Con Git:** `git clone https://github.com/romu545/codigo-datos-criterio-material.git`
- **Sin Git:** en la página del repositorio, botón **Code → Download ZIP**, y descomprime la carpeta.

Abre la carpeta descargada en Positron (**File → Open Folder…**). Todos los ejemplos del libro usan rutas relativas a esta carpeta, como `datos/cap03/ventas_2026_01.csv`.

## Contenido

| Carpeta | Capítulo | Qué contiene |
|---|---|---|
| `datos/cap03/` | 3. Importación de datos I: el contrato de lectura | Ventas en CSV con codificación `Latin-1`, lotes mensuales con deriva de esquema y un chat de soporte en texto plano |
| `datos/cap04/` | 4. Importación de datos II: formatos y fuentes | Libros de Excel, una respuesta de API en JSON y una base DuckDB |
| `datos/cap05/` | 5. Importación de datos III: limpieza temprana | Una exportación de cartera en CSV y un libro de visitas en Excel, con nombres, faltantes, booleanos y fechas por resolver al leer |
| `datos/cap06/` | 6. Tipos de datos y calidad | La cartera del primer trimestre, los clientes y los recaudos en Parquet, con problemas de calidad sembrados para auditar |
| `datos/cap07/` | 7. Transformación y limpieza I: transformar y ordenar | Ventas, productos, sucursales, metas en formato ancho y pedidos con varios productos por celda; el archivo de 10 millones de filas se genera con un script |
| `datos/cap08/` | 8. Transformación y limpieza II: limpiar | Una exportación de CRM con textos escritos de varias formas y clientes repetidos; la limpieza completa usa la cartera de `datos/cap06/` |
| `scripts/` | | Scripts que generan los datos |

Cada carpeta de datos tiene su propio `README.md` con el detalle de los archivos.

## Cómo generar los datos

Algunos archivos no se guardan en el repositorio, o se pueden volver a crear. Desde la carpeta raíz, en la terminal:

```bash
# Capítulo 4: CSV de unos 2,5 millones de filas para el ejercicio CSV frente a Parquet
Rscript scripts/generar_ventas_historico_grande.R

# Capítulo 5: cartera y visitas comerciales
Rscript scripts/generar_datos_cap05.R

# Capítulo 6: cartera del trimestre, clientes y recaudos
Rscript scripts/generar_datos_cap06.R

# Capítulo 7: ventas, catálogos, metas, pedidos y el archivo grande (unos 120 MB)
Rscript scripts/generar_datos_cap07.R

# Capítulo 8: exportación del CRM
Rscript scripts/generar_datos_cap08.R
```

La carpeta `scripts/` también tiene `auditoria_cartera.R` y `auditoria_cartera.py`, con las reglas de calidad del capítulo 6 que el capítulo 8 reutiliza.

Los scripts necesitan los paquetes de R `DBI`, `duckdb`, `arrow` y `openxlsx2`, que se instalan al comienzo del capítulo 3 del libro.

## Licencias

- **Código** (carpeta `scripts/` y fragmentos de código): licencia [MIT](LICENSE).
- **Datos:** todos los conjuntos de este repositorio son **sintéticos**, creados para el libro. No corresponden a personas ni a empresas reales, y se distribuyen bajo la misma licencia MIT. Los datos que en el libro se descargan de fuentes externas (por ejemplo, [datos.gov.co](https://www.datos.gov.co)) conservan la licencia de su fuente y no se incluyen aquí.
- **Texto del libro:** [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.es), en el repositorio del libro.

## Reportar errores

Los errores en los datos o en el libro se reportan en los [issues del repositorio del libro](https://github.com/romu545/codigo-datos-criterio/issues).
