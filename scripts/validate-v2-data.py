"""Validate v2 contracts and existing data without treating legacy stats as v2."""
import argparse
import copy
import json
from pathlib import Path

from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[1]
SCHEMAS = ROOT / "data/schemas"


def load(path):
    return json.loads(path.read_text(encoding="utf-8"))


def validate(kind, data):
    schema = load(SCHEMAS / f"{kind}.schema.json")
    Draft202012Validator(schema).validate(data)
    if kind == "atlas":
        width, height = data["tamano"]
        for frame in data["frames"].values():
            if frame["x"] + frame["w"] > width or frame["y"] + frame["h"] > height:
                raise ValueError("Atlas frame outside image")
        for anim in data["animaciones"].values():
            if not set(anim["frames"]).issubset(data["frames"]):
                raise ValueError("Animation references missing frame")
    if kind == "shop":
        for upgrade in data["mejoras"]:
            if len(upgrade["costos"]) != upgrade["rangos"]:
                raise ValueError("Upgrade needs one price per rank")
    if kind == "legacy_inventory":
        entities = {e["id"]: e for e in data["entities"]}
        if len(entities) != len(data["entities"]):
            raise ValueError("Duplicate legacy type")
        if [w["id"] for w in data["worlds"]] != list(range(1, 15)):
            raise ValueError("Expected worlds 1 through 14")
        for world in data["worlds"]:
            for role in ("unique", "recurrent"):
                for key in world[role]:
                    if {"world": world["id"], "role": role} not in entities[key]["appearances"]:
                        raise ValueError("Missing legacy appearance")
            for boss in world["bosses"]:
                if boss["type"] not in entities:
                    raise ValueError("Missing boss type")


def validate_file(kind, path):
    data = load(path)
    validate(kind, data)
    if kind == "waves" and path.name.startswith("world_"):
        if data["mundo"] != int(path.stem.removeprefix("world_")):
            raise ValueError("Wave world differs from filename")


def self_test():
    cases = {
        "worlds": (lambda x: x[0].update(enemigos_total=-1)),
        "enemies": (lambda x: x[0].update(id="INVALID ID")),
        "bosses": (lambda x: x[0].update(vida=-1)),
        "shop": (lambda x: x["mejoras"][0].update(costos=[1])),
        "cosmetics": (lambda x: x[0].update(id="INVALID ID")),
        "audio": (lambda x: x[0].update(volumen=2)),
        "waves": (lambda x: x["eventos"][0].update(cantidad=-1)),
        "escape": (lambda x: x.update(duracion_seg=0)),
        "atlas": (lambda x: x["frames"][next(iter(x["frames"]))].update(x=1024)),
        "assets_manifest": (lambda x: x["assets"][0].update(estado="inventado")),
    }
    for kind, mutate in cases.items():
        example = load(SCHEMAS / f"{kind}.schema.json")["examples"][0]
        validate(kind, example)
        bad = copy.deepcopy(example)
        mutate(bad)
        try:
            validate(kind, bad)
        except (ValueError, __import__("jsonschema").ValidationError):
            pass
        else:
            raise AssertionError(f"{kind} accepted invalid data")
    atlas = load(SCHEMAS / "atlas.schema.json")["examples"][0]
    atlas["animaciones"]["move"]["frames"] = ["missing"]
    try:
        validate("atlas", atlas)
    except ValueError:
        pass
    else:
        raise AssertionError("Missing frame accepted")
    # Check filename/world agreement without creating temporary repository data.
    import tempfile
    with tempfile.TemporaryDirectory() as tmp:
        wave = load(SCHEMAS / "waves.schema.json")["examples"][0]
        target = Path(tmp) / "world_02.json"
        target.write_text(json.dumps(wave), encoding="utf-8")
        try:
            validate_file("waves", target)
        except ValueError:
            pass
        else:
            raise AssertionError("Wrong wave world accepted")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    schemas = sorted(SCHEMAS.glob("*.schema.json"))
    if not schemas:
        raise ValueError("No schemas found")
    for path in schemas:
        Draft202012Validator.check_schema(load(path))
    validate_file("legacy_inventory", ROOT / "data/legacy_inventory.json")
    # Validate populated future data as soon as its owning phase adds it.
    for kind in ("worlds", "enemies", "bosses", "shop", "cosmetics", "audio", "escape"):
        path = ROOT / f"data/{kind}.json"
        if path.exists():
            validate_file(kind, path)
    for path in (ROOT / "data/waves").glob("world_*.json"):
        validate_file("waves", path)
    for path in (ROOT / "assets/atlas").glob("w*.json"):
        validate_file("atlas", path)
    manifest = ROOT / "assets/assets_manifest.json"
    if manifest.exists():
        validate_file("assets_manifest", manifest)
    if args.self_test:
        self_test()
    print(f"{len(schemas)} contracts verified; legacy inventory valid. Future content is not yet implemented.")


if __name__ == "__main__":
    main()
