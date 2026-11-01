"""Generate reviewable economy tables from the editable native shop contract."""
import csv
import math
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def generate():
    data = json.loads((ROOT / "data/shop.json").read_text(encoding="utf-8"))
    balance = []
    cumulative = 0
    unlocked_cost = 0
    all_upgrades = sum(sum(u["costos"]) for u in data["mejoras"])
    seen_acts = set()
    for visit in data["economia"]:
        row = dict(visit)
        cumulative += row["base_monedas"]
        equipment = [g for g in data["equipo"] if g["acto"] == row["acto"]] if row["acto"] not in seen_acts else []
        seen_acts.add(row["acto"])
        unlocked_cost += sum(g["costo"] for g in equipment)
        row.update(bono_sin_morir=row["base_monedas"] // 5,
                   acumulado=cumulative,
                   acumulado_con_bono=cumulative * 6 // 5,
                   equipo_desbloqueado=";".join(g["id"] for g in equipment),
                   vida_enemigo_pequeno=math.ceil(row["dps_ref"] / 10),
                   gasto_maximo_desbloqueado=all_upgrades + unlocked_cost,
                   gasto_maximo_asequible=min(cumulative, all_upgrades + unlocked_cost))
        balance.append(row)
    shop = []
    expense = 0
    for upgrade in data["mejoras"]:
        for rank, price in enumerate(upgrade["costos"], 1):
            expense += price
            shop.append(dict(tipo="mejora", id=upgrade["id"], rango=rank,
                             costo=price, acumulado=expense, acto=1,
                             efecto=json.dumps(upgrade["efecto_por_rango"], ensure_ascii=False, sort_keys=True)))
    for gear in data["equipo"]:
        expense += gear["costo"]
        shop.append(dict(tipo="equipo", id=gear["id"], rango=1,
                         costo=gear["costo"], acumulado=expense,
                         acto=gear["acto"], efecto=gear["efecto"]))
    assert cumulative == 17900
    assert cumulative * 6 // 5 == 21480
    assert all_upgrades == 19850
    assert expense == 30450
    columns = ["mundo", "acto", "enemigos", "duracion_hasta_jefe_seg", "jefe_objetivo_seg", "base_monedas", "bono_sin_morir", "acumulado", "equipo_desbloqueado", "vida_enemigo_pequeno", "vida_jefe", "vida_minijefe", "dps_ref", "acumulado_con_bono", "gasto_maximo_desbloqueado", "gasto_maximo_asequible"]
    for name, rows, fields in [("balance_sheet", balance, columns), ("shop_sheet", shop, list(shop[0]))]:
        with (ROOT / f"docs/{name}.csv").open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)
    print(f"17 visits; income {cumulative}/21480; upgrades {all_upgrades}; shop {expense}")


if __name__ == "__main__":
    generate()
