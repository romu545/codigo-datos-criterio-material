"""Pruebas de las funciones del flujo de entregas (capítulos 13 y 17).

Uso, desde la carpeta raíz del proyecto:

    uv run pytest tests
"""

import pandas as pd
import pytest

from scripts.flujo_entregas import armonizar, resumir, validar


def tabla_minima(**cambios):
    """Una tabla mínima, escrita a mano, con lo justo para probar cada caso."""
    base = pd.DataFrame(
        {
            "pedido": ["P1", "P2"],
            "fecha": ["2026-03-01", "2026-03-02"],
            "sucursal": ["S01", "S01"],
            "canal": ["domicilio", "web"],
            "distancia_km": ["5", "8"],
            "tiempo_entrega_h": ["10", "30"],
            "unidades": ["2", "3"],
            "valor_pedido": ["100000", "200000"],
            "calificacion": ["5", "2"],
            "devuelto": ["FALSE", "TRUE"],
        }
    )
    for columna, valores in cambios.items():
        base[columna] = valores
    return base


def test_armonizar_convierte_minutos_a_horas():
    abril = (
        tabla_minima()
        .drop(columns="tiempo_entrega_h")
        .assign(tiempo_entrega_min=["600", "1800"])
    )
    resultado = armonizar({"abril": abril})
    assert resultado["tiempo_entrega_h"].tolist() == [10, 30]
    assert "tiempo_entrega_min" not in resultado.columns


def test_validar_detiene_si_hay_fechas_sin_leer():
    datos = armonizar(
        {"malo": tabla_minima(fecha=["2026-03-01", "2026-03-02"])}
    )
    datos.loc[1, "fecha"] = pd.NaT
    with pytest.raises(ValueError, match="fechas sin leer"):
        validar(datos)


def test_validar_detiene_si_llegan_minutos_en_horas():
    datos = armonizar(
        {"minutos": tabla_minima(tiempo_entrega_h=["600", "1800"])}
    )
    with pytest.raises(ValueError, match="más de 72 horas"):
        validar(datos)


def test_resumir_calcula_los_porcentajes():
    indicadores = resumir(validar(armonizar({"t": tabla_minima()})))
    assert indicadores["pedidos"].tolist() == [2]
    assert indicadores["pct_tardias"].tolist() == [50.0]
