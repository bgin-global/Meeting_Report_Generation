import os
import sys
import re

def parse_segments(text):
    # セグメントの開始時刻とテキストを抽出
    segments = []
    pattern = re.compile(r"(\d+\.\d+)\s*-->\s*(\d+\.\d+):\s*(.*)")

    for line in text.strip().splitlines():
        match = pattern.match(line.strip())
        if match:
            start = float(match.group(1))
            end = float(match.group(2))
            content = match.group(3)
            segments.append((start, end, content))
    return segments

def split_text(input_file, output_dir, base_filename, max_lines_per_file=25):
    with open(input_file, 'r', encoding='utf-8') as f:
        text = f.read()

    segments = parse_segments(text)

    # セグメントを時系列順にソート（念のため）
    segments.sort(key=lambda x: x[0])

    os.makedirs(output_dir, exist_ok=True)

    part_number = 1
    lines_in_file = 0
    current_file = os.path.join(output_dir, f"{base_filename}_part{part_number}.txt")
    current_output = open(current_file, 'w', encoding='utf-8')

    for start, end, content in segments:
        line = f"{start:.2f} --> {end:.2f}: {content}\n"
        current_output.write(line)
        lines_in_file += 1

        if lines_in_file >= max_lines_per_file:
            current_output.close()
            part_number += 1
            lines_in_file = 0
            current_file = os.path.join(output_dir, f"{base_filename}_part{part_number}.txt")
            current_output = open(current_file, 'w', encoding='utf-8')

    current_output.close()
    print(f"✅ Split into {part_number} parts.")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python split_text.py <input_file> <output_dir> <base_filename>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_dir = sys.argv[2]
    base_filename = sys.argv[3]

    print("split_text args:")
    print(f"  Input file     : {input_file}")
    print(f"  Output dir     : {output_dir}")
    print(f"  Base filename  : {base_filename}")

    split_text(input_file, output_dir, base_filename)
