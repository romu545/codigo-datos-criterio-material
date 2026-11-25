"""Reglas de calidad de la cartera (capítulo 6), reunidas para reutilizarlas.

Uso, desde la carpeta raíz del proyecto:

    from scripts.auditoria_cartera import reglas_cartera, auditar
    reglas = reglas_cartera(clientes)
    reporte = auditar(cartera, reglas)

Cada regla dice qué filas CUMPLEN; las reglas de validez dejan pasar los
faltantes de forma explícita, porque de ellos se encargan las de completitud.
Las fechas de la cartera deben estar como datetime64 (pd.to_datetime).
"""

import pandas as pd


def reglas_cartera(clientes, inicio="2026-01-01", corte="2026-03-31"):
    inicio, corte = pd.Timestamp(inicio), pd.Timestamp(corte)
    ciudades = clientes["ciudad"].unique()
    nits = clientes["nit"]
    return [
        ("nit_presente", "Completitud", "bloquea",
         lambda d: d["nit"].notna()),
        ("ciudad_presente", "Completitud", "advierte",
         lambda d: d["ciudad"].notna()),
        ("factura_unica", "Unicidad", "bloquea",
         lambda d: ~d["factura"].duplicated(keep=False)),
        ("valor_positivo", "Validez", "bloquea",
         lambda d: d["valor_factura"] > 0),
        ("calificacion_1_a_5", "Validez", "advierte",
         lambda d: d["calificacion"].isna() | d["calificacion"].between(1, 5)),
        ("emision_en_periodo", "Validez", "bloquea",
         lambda d: d["fecha_emision"].between(inicio, corte)),
        ("nit_10_digitos", "Validez", "bloquea",
         lambda d: d["nit"].isna() | d["nit"].str.fullmatch(r"\d{10}")),
        ("ciudad_en_catalogo", "Validez", "advierte",
         lambda d: d["ciudad"].isna() | d["ciudad"].isin(ciudades)),
        ("pago_despues_emision", "Consistencia", "bloquea",
         lambda d: d["fecha_pago"].isna() | (d["fecha_pago"] >= d["fecha_emision"])),
        ("pagada_con_fecha", "Consistencia", "bloquea",
         lambda d: d["pagada"] == d["fecha_pago"].notna()),
        ("pagada_sin_saldo", "Consistencia", "bloquea",
         lambda d: ~d["pagada"] | (d["saldo"] == 0)),
        ("saldo_hasta_valor", "Consistencia", "bloquea",
         lambda d: d["saldo"] <= d["valor_factura"]),
        ("nit_en_clientes", "Integridad", "bloquea",
         lambda d: d["nit"].isna() | d["nit"].isin(nits)),
        ("valor_plausible", "Plausibilidad", "advierte",
         lambda d: d["valor_factura"] <= 50_000_000),
    ]


def auditar(datos, reglas):
    """Devuelve el reporte: cuántas filas falla cada regla."""
    marcas = pd.DataFrame(
        {regla: ~cumple(datos).astype(bool) for regla, _, _, cumple in reglas},
        index=datos.index,
    )
    reporte = pd.DataFrame([r[:3] for r in reglas],
                           columns=["regla", "dimension", "severidad"])
    reporte["filas"] = marcas.sum().to_numpy()
    return reporte
