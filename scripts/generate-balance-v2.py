"""Generate reviewable economy tables from the editable native shop contract."""
import csv
import math
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def generate():
    data = json.loads((ROOT / "data/shop.json").read_text(encoding="utf-8"))
    campaign_path = ROOT / 'data/campaign.json'
    campaign = json.loads(campaign_path.read_text()) if campaign_path.exists() else None
    worlds = {w['id']: w for w in json.loads((ROOT/'data/worlds.json').read_text())} if campaign else {}
    bosses = {b['id']: b for b in json.loads((ROOT/'data/bosses.json').read_text())} if campaign else {}
    economy = json.loads((ROOT/'data/campaign_economy.json').read_text())['after'] if campaign else {}
    incomes = {w['world']: w for w in economy.get('worlds', [])}
    balance = []
    cumulative = 0
    cumulative_with_bonus = 0
    visits_seen = {}
    unlocked_cost = 0
    all_upgrades = sum(sum(u["costos"]) for u in data["mejoras"])
    seen_acts = set()
    for visit in data["economia"]:
        row = dict(visit)
        income = row['base_monedas']
        bonus = row['base_monedas'] // 5
        if campaign:
            world_id = int(str(row['mundo']).split()[0])
            world = worlds[world_id]
            budget = incomes[world_id]
            room = visits_seen.get(world_id, 0)
            visits_seen[world_id] = room + 1
            stage_coins = budget['stage_coins'] if room == 0 else 0
            victory = budget['victory'] * row['base_monedas'] / budget['base']
            bonus = budget['no_death_bonus'] * row['base_monedas'] / budget['base']
            room_coins = 0
            if world_id == campaign['laboratory_id']:
                ids = world['sectores_jefes'][room]['jefes']
                if room:
                    later_base = sum(s['base_monedas'] for s in world['sectores_jefes'][1:])
                    room_coins = budget['later_room_coins'] * row['base_monedas'] / later_base
            else:
                ids = world['jefes']
            income = stage_coins + room_coins + victory
            row.update(monedas_etapa=stage_coins, monedas_sala=room_coins,
                       recompensa_jefe=victory, ingreso_ideal=income+bonus,
                       vida_jefe_actual=sum(bosses[key]['vida'] for key in ids))
        cumulative += income
        cumulative_with_bonus += income + bonus
        equipment = [g for g in data["equipo"] if g["acto"] == row["acto"]] if row["acto"] not in seen_acts else []
        seen_acts.add(row["acto"])
        unlocked_cost += sum(g["costo"] for g in equipment)
        row.update(bono_sin_morir=bonus,
                   acumulado=cumulative,
                   acumulado_con_bono=cumulative_with_bonus,
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
    if campaign:
        assert len(balance) == campaign['world_count'] - 1 + campaign['lab_encounters']
        assert cumulative_with_bonus == economy['total']
    else:
        assert cumulative == 17900
        assert cumulative_with_bonus == 21480
    assert all_upgrades == 19850
    assert expense == 30450
    columns = ["mundo", "acto", "enemigos", "duracion_hasta_jefe_seg", "jefe_objetivo_seg", "base_monedas", "bono_sin_morir", "acumulado", "equipo_desbloqueado", "vida_enemigo_pequeno", "vida_jefe", "vida_minijefe", "dps_ref", "acumulado_con_bono", "gasto_maximo_desbloqueado", "gasto_maximo_asequible"]
    if campaign:
        columns += ['monedas_etapa', 'monedas_sala', 'recompensa_jefe', 'ingreso_ideal', 'vida_jefe_actual']
    for name, rows, fields in [("balance_sheet", balance, columns), ("shop_sheet", shop, list(shop[0]))]:
        with (ROOT / f"docs/{name}.csv").open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)
    print(f"{len(balance)} visits; income {cumulative}/{cumulative_with_bonus}; upgrades {all_upgrades}; shop {expense}")


if __name__ == "__main__":
    generate()
