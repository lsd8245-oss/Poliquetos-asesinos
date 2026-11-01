#!/usr/bin/env python3
"""Render original gameplay SFX from numeric design; no samples or music input.

Run from any directory. --check verifies byte-for-byte reproducibility without writing.
Mono, 44100 Hz, signed PCM16 WAV. Python standard library only.
"""
import argparse
import hashlib
import io
import json
import math
from pathlib import Path
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100


def render(effect):
    rng = random.Random(effect["seed"])
    duration = effect["duration_ms"] / 1000
    count = round(duration * RATE)
    phase = 0.0
    filtered = 0.0
    cutoff = 1 - math.exp(-2 * math.pi * effect["noise_cutoff_hz"] / RATE)
    samples = []
    for index in range(count):
        t = index / RATE
        progress = index / max(1, count - 1)
        frequency = effect["start_hz"] * (effect["end_hz"] / effect["start_hz"]) ** progress
        frequency *= 1 + effect["vibrato_depth"] * math.sin(math.tau * effect["vibrato_hz"] * t)
        phase += math.tau * frequency / RATE
        tone = math.sin(phase) + effect["harmonic_mix"] * math.sin(phase * effect["harmonic_ratio"])
        pulse = 1.0 if math.sin(phase) >= 0 else -1.0
        tone = tone * (1 - effect["pulse_mix"]) + pulse * effect["pulse_mix"]
        white = rng.uniform(-1, 1)
        filtered += cutoff * (white - filtered)
        noise = filtered * (1 - effect["noise_highpass_mix"]) + (white - filtered) * effect["noise_highpass_mix"]
        envelope = min(1, t / (effect["attack_ms"] / 1000))
        envelope *= math.exp(-effect["decay"] * progress)
        envelope *= min(1, (duration - t) / (effect["release_ms"] / 1000))
        envelope *= 1 - effect["tremolo_depth"] * (0.5 + 0.5 * math.sin(math.tau * effect["tremolo_hz"] * t))
        samples.append((tone * effect["tone_mix"] + noise * effect["noise_mix"]) * envelope)
    peak = max(abs(sample) for sample in samples) or 1
    pcm = b"".join(struct.pack("<h", round(sample / peak * effect["peak"] * 32767)) for sample in samples)
    output = io.BytesIO()
    with wave.open(output, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm)
    return output.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    design = json.loads((ROOT / "data/sfx_design.json").read_text())
    catalog = []
    for effect in design["effects"]:
        relative = f"assets/audio/sfx/{effect['id']}.wav"
        path = ROOT / relative
        content = render(effect)
        if args.check:
            if not path.exists() or path.read_bytes() != content:
                raise SystemExit(f"SFX does not match numeric design: {relative}")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
        catalog.append({"id": effect["id"], "ruta": relative, "volumen": effect["volume"],
                        "loop_start": 0, "loop_end": effect["duration_ms"] / 1000,
                        "tipo": "sfx", "prioridad": effect["priority"]})
    encoded = json.dumps(catalog, ensure_ascii=False, indent=2) + "\n"
    catalog_path = ROOT / "data/audio.json"
    if args.check:
        if catalog_path.read_text() != encoded:
            raise SystemExit("Audio catalog does not match design")
    else:
        catalog_path.write_text(encoded)
    digest = hashlib.sha256(b"".join(render(effect) for effect in design["effects"])).hexdigest()
    print(f"{len(catalog)} original PCM16 mono / {RATE} Hz effects {'verified' if args.check else 'generated'}; SHA256 {digest}")


if __name__ == "__main__":
    main()
