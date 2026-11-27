"""Funciones de inventario (capítulos 9 y 12).

Uso, desde la carpeta raíz del proyecto:

    from scripts.inventario import PoliticaInventario, simular_con
    simular_con(demanda, PoliticaInventario(reorden=80))
"""

from dataclasses import dataclass, asdict

import pandas as pd


@dataclass(frozen=True)
class PoliticaInventario:
    """Una política de inventario validada."""

    inicial: float = 120
    reorden: float = 50
    lote: float = 100
    espera: int = 5

    def __post_init__(self):
        for nombre, valor in asdict(self).items():
            if not isinstance(valor, (int, float)) or isinstance(valor, bool):
                raise TypeError(f"{nombre} debe ser un número, no {valor!r}")
            if valor < 0:
                raise ValueError(f"{nombre} no puede ser negativo")
        if self.lote <= 0:
            raise ValueError("el lote debe ser mayor que cero")
        if self.espera < 1:
            raise ValueError("la espera debe ser de al menos un día")


def simular_inventario(demanda, inicial=120, reorden=50, lote=100, espera=5):
    """Simula el inventario día a día (capítulo 9)."""
    inventario, perdidas = [0] * len(demanda), [0] * len(demanda)
    disponible, llegada = inicial, None
    for t, pedido in enumerate(demanda):
        if llegada == t:
            disponible += lote
            llegada = None
        vendido = min(pedido, disponible)
        perdidas[t] = pedido - vendido
        disponible -= vendido
        if disponible < reorden and llegada is None:
            llegada = t + espera
        inventario[t] = disponible
    return pd.DataFrame({"inventario": inventario, "perdidas": perdidas})


def simular_con(demanda, politica):
    """Simula con una PoliticaInventario."""
    if not isinstance(politica, PoliticaInventario):
        raise TypeError("politica debe ser una PoliticaInventario")
    return simular_inventario(demanda, **asdict(politica))
