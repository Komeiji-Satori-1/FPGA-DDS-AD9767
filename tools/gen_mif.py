import argparse
import math
from pathlib import Path


def clamp(value, low, high):
    return max(low, min(high, value))


def sine_sample(index, depth, max_code):
    angle = 2.0 * math.pi * index / depth
    mid = max_code / 2.0
    amp = max_code / 2.0
    return int(round(mid + amp * math.sin(angle)))


def square_sample(index, depth, max_code):
    return max_code if index < depth // 2 else 0


def triangle_sample(index, depth, max_code):
    phase = index / depth
    if phase < 0.5:
        value = phase * 2.0 * max_code
    else:
        value = (1.0 - phase) * 2.0 * max_code
    return int(round(value))


def build_samples(wave, depth, width):
    max_code = (1 << width) - 1
    samples = []

    for index in range(depth):
        if wave == "sine":
            sample = sine_sample(index, depth, max_code)
        elif wave == "square":
            sample = square_sample(index, depth, max_code)
        elif wave == "triangle":
            sample = triangle_sample(index, depth, max_code)
        else:
            raise ValueError("unsupported wave type")

        samples.append(clamp(sample, 0, max_code))

    return samples


def write_mif(path, samples, width):
    path.parent.mkdir(parents=True, exist_ok=True)
    depth = len(samples)
    hex_digits = (width + 3) // 4

    with path.open("w", encoding="ascii", newline="\n") as file:
        file.write(f"WIDTH={width};\n")
        file.write(f"DEPTH={depth};\n\n")
        file.write("ADDRESS_RADIX=UNS;\n")
        file.write("DATA_RADIX=HEX;\n\n")
        file.write("CONTENT BEGIN\n")
        for address, sample in enumerate(samples):
            file.write(f"    {address} : {sample:0{hex_digits}x};\n")
        file.write("END;\n")


def write_hex(path, samples, width):
    path.parent.mkdir(parents=True, exist_ok=True)
    hex_digits = (width + 3) // 4

    with path.open("w", encoding="ascii", newline="\n") as file:
        for sample in samples:
            file.write(f"{sample:0{hex_digits}x}\n")


def main():
    parser = argparse.ArgumentParser(description="Generate DAC waveform ROM files.")
    parser.add_argument("--wave", choices=["sine", "square", "triangle"], required=True)
    parser.add_argument("--width", type=int, default=14)
    parser.add_argument("--depth", type=int, default=16384)
    parser.add_argument("--mif", type=Path, required=True)
    parser.add_argument("--hex", type=Path)
    args = parser.parse_args()

    samples = build_samples(args.wave, args.depth, args.width)
    write_mif(args.mif, samples, args.width)
    if args.hex:
        write_hex(args.hex, samples, args.width)


if __name__ == "__main__":
    main()

