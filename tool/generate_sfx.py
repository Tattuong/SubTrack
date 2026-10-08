#!/usr/bin/env python3
"""Generate short WAV sound effects for Find The Rule."""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "sfx"
RATE = 44100


def synth(duration: float, fn) -> list[int]:
    n = int(RATE * duration)
    return [max(-32767, min(32767, int(fn(t / RATE)))) for t in range(n)]


def fade(samples: list[int], attack: float = 0.01, release: float = 0.08) -> list[int]:
    n = len(samples)
    a = int(n * attack)
    r = int(n * release)
    out = samples[:]
    for i in range(a):
        out[i] = int(out[i] * (i / max(a, 1)))
    for i in range(r):
        k = (r - i) / max(r, 1)
        out[n - 1 - i] = int(out[n - 1 - i] * k)
    return out


def mix(*tracks: list[int]) -> list[int]:
    n = max(len(t) for t in tracks)
    out = [0] * n
    for track in tracks:
        for i, v in enumerate(track):
            out[i] += v
    peak = max(1, max(abs(v) for v in out))
    scale = min(1.0, 28000 / peak)
    return [int(v * scale) for v in out]


def tone(freq: float, duration: float, amp: float = 0.35) -> list[int]:
    return synth(
        duration,
        lambda t: amp * 32767 * math.sin(2 * math.pi * freq * t),
    )


def sweep(f0: float, f1: float, duration: float, amp: float = 0.25) -> list[int]:
    return synth(
        duration,
        lambda t: amp
        * 32767
        * math.sin(2 * math.pi * (f0 + (f1 - f0) * (t / duration)) * t),
    )


def save(name: str, samples: list[int]) -> None:
    path = OUT / name
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(RATE)
        wf.writeframes(b"".join(struct.pack("<h", s) for s in fade(samples)))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    save("tap.wav", tone(920, 0.06, 0.28))
    save(
        "correct.wav",
        mix(
            tone(523, 0.11, 0.32),
            [0] * int(RATE * 0.07) + tone(659, 0.11, 0.30),
            [0] * int(RATE * 0.14) + tone(784, 0.16, 0.28),
        ),
    )
    save(
        "wrong.wav",
        mix(
            tone(220, 0.18, 0.34),
            [0] * int(RATE * 0.08) + tone(185, 0.22, 0.30),
        ),
    )
    save(
        "level.wav",
        mix(
            tone(523, 0.10, 0.30),
            [0] * int(RATE * 0.08) + tone(659, 0.10, 0.28),
            [0] * int(RATE * 0.16) + tone(784, 0.10, 0.26),
            [0] * int(RATE * 0.24) + tone(1047, 0.18, 0.24),
        ),
    )
    save("hint.wav", mix(tone(740, 0.08, 0.26), [0] * int(RATE * 0.05) + tone(988, 0.12, 0.22)))
    save("navigate.wav", sweep(420, 880, 0.14, 0.22))

    print(f"Generated {len(list(OUT.glob('*.wav')))} files in {OUT}")


if __name__ == "__main__":
    main()
