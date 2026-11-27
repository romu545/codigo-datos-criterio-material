"""Flujo de las entregas (capítulo 13): de los CSV mensuales a los indicadores.

Uso desde Python, en la carpeta raíz del proyecto:

    from scripts.flujo_entregas import ejecutar_flujo, PASOS
    resultado = ejecutar_flujo(rutas, PASOS)

Uso desde la terminal (ejecuta el flujo completo en un proceso nuevo):

    uv run python -m scripts.flujo_entregas datos/cap13/entregas
"""

import logging
import sys
import time
from pathlib import Path

import pandas as pd

ESPERADAS = [
    "pedido",
    "fecha",
    "sucursal",
    "canal",
    "distancia_km",
    "tiempo_entrega_h",
    "unidades",
    "valor_pedido",
    "calificacion",
    "devuelto",
]

log = logging.getLogger("flujo_entregas")


def leer_crudo(rutas):
    """Lee cada archivo como texto, sin adivinar tipos."""
    if not rutas:
        raise ValueError("no hay archivos para leer")
    return {Path(r).name: pd.read_csv(r, dtype=str) for r in rutas}


def armonizar(tablas):
    """Lleva cada archivo al mismo esquema y convierte los tipos."""
    partes = []
    for archivo, d in tablas.items():
        d = d.copy()
        if "tiempo_entrega_min" in d.columns:
            d["tiempo_entrega_h"] = (
                pd.to_numeric(d.pop("tiempo_entrega_min")) / 60
            )
        iso = d["fecha"].str.match(r"^\d{4}-\d{2}-\d{2}$")
        d["fecha"] = pd.concat(
            [
                pd.to_datetime(d.loc[iso, "fecha"], format="%Y-%m-%d"),
                pd.to_datetime(d.loc[~iso, "fecha"], format="%d/%m/%Y"),
            ]
        ).sort_index()
        partes.append(d.assign(archivo=archivo))
    d = pd.concat(partes, ignore_index=True)
    for c in ["distancia_km", "tiempo_entrega_h", "unidades", "valor_pedido"]:
        d[c] = pd.to_numeric(d[c])
    d["calificacion"] = pd.to_numeric(d["calificacion"]).astype("Int64")
    d["devuelto"] = d["devuelto"].map({"TRUE": True, "FALSE": False})
    return d


def validar(d):
    """Detiene el flujo si los datos no cumplen las reglas que bloquean."""
    problemas = []
    faltan = set(ESPERADAS) - set(d.columns)
    if faltan:
        problemas.append(f"faltan columnas: {', '.join(sorted(faltan))}")
    if d["fecha"].isna().any():
        archivos = ", ".join(d.loc[d["fecha"].isna(), "archivo"].unique())
        problemas.append(
            f"{d['fecha'].isna().sum()} fechas sin leer en {archivos}"
        )
    if d["pedido"].duplicated().any():
        problemas.append(f"{d['pedido'].duplicated().sum()} pedidos repetidos")
    if (d["tiempo_entrega_h"] > 72).any():
        problemas.append(
            f"{(d['tiempo_entrega_h'] > 72).sum()} tiempos de más de 72 horas"
        )
    sin_tiempo = d["tiempo_entrega_h"].isna() & (d["canal"] != "retiro")
    if sin_tiempo.any():
        problemas.append(
            f"{sin_tiempo.sum()} entregas a domicilio sin tiempo de entrega"
        )
    if problemas:
        raise ValueError(
            "los datos no pasan la validación:\n- " + "\n- ".join(problemas)
        )
    return d


def resumir(d):
    """Indicadores mensuales por sucursal."""
    a_domicilio = d[d["canal"] != "retiro"].assign(
        mes=lambda x: x["fecha"].dt.strftime("%Y-%m"),
        tardia=lambda x: x["tiempo_entrega_h"] > 20,
    )
    return a_domicilio.groupby(["mes", "sucursal"], as_index=False).agg(
        pedidos=("pedido", "size"),
        mediana_horas=("tiempo_entrega_h", "median"),
        pct_tardias=("tardia", lambda x: round(100 * x.mean(), 1)),
        pct_devueltos=("devuelto", lambda x: round(100 * x.mean(), 1)),
    )


def guardar(indicadores, ruta="datos/cap13/salida/indicadores_py.csv"):
    """Guarda los indicadores y los devuelve sin cambios."""
    Path(ruta).parent.mkdir(parents=True, exist_ok=True)
    indicadores.to_csv(ruta, index=False)
    return indicadores


PASOS = {
    "leer": leer_crudo,
    "armonizar": armonizar,
    "validar": validar,
    "resumir": resumir,
    "guardar": guardar,
}


def ejecutar_flujo(
    entrada, pasos, bitacora="datos/cap13/salida/bitacora_py.log"
):
    """Ejecuta los pasos en orden y registra cada uno en la bitácora."""
    Path(bitacora).parent.mkdir(parents=True, exist_ok=True)
    if not log.handlers:
        log.setLevel(logging.INFO)
        formato = logging.Formatter(
            "%(asctime)s  %(message)s", "%Y-%m-%d %H:%M:%S"
        )
        for manejador in (
            logging.FileHandler(bitacora, encoding="utf-8"),
            logging.StreamHandler(sys.stdout),
        ):
            manejador.setFormatter(formato)
            log.addHandler(manejador)
    log.info("inicio del flujo: %d pasos", len(pasos))
    datos = entrada
    for nombre, paso in pasos.items():
        inicio = time.perf_counter()
        try:
            datos = paso(datos)
        except Exception as e:
            log.error("FALLÓ el paso '%s'", nombre)
            raise RuntimeError(f"el paso '{nombre}' falló: {e}") from e
        filas = (
            len(datos)
            if isinstance(datos, pd.DataFrame)
            else sum(map(len, datos.values()))
        )
        log.info(
            "%-10s %6d filas  %5.2f s",
            nombre,
            filas,
            time.perf_counter() - inicio,
        )
    log.info("fin del flujo")
    return datos


if __name__ == "__main__":
    carpeta = sys.argv[1] if len(sys.argv) > 1 else "datos/cap13/entregas"
    ejecutar_flujo(sorted(str(p) for p in Path(carpeta).glob("*.csv")), PASOS)
