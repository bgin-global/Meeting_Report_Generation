import sys
import os
import re
from utils.logging import debug, info, success

def parse_segments(text):
    # Extract segment start time and text
    segments = []
    pattern = re.compile(r"(\d+\.\d+)\s*-->\s*(\d+\.\d+):\s*(.*)")

    for line in text.strip().split("\n"):
        match = pattern.match(line.strip())
        if match:
            start_time = float(match.group(1))
            end_time = float(match.group(2))
            text = match.group(3).strip()
            segments.append((start_time, end_time, text))

    return segments

def split_text(input_file, output_dir, base_filename, max_time_per_file=1800):
    with open(input_file, "r", encoding="utf-8") as f:
        text = f.read()

    segments = parse_segments(text)

    # Sort segments chronologically (just in case)
    segments.sort(key=lambda x: x[0])

    os.makedirs(output_dir, exist_ok=True)
    
    current_part = 1
    current_file = []
    last_time = 0

    for start_time, end_time, text in segments:
        if start_time - last_time > max_time_per_file and current_file:
            # Write current part
            output_file = os.path.join(output_dir, f"{base_filename}_part{current_part}.txt")
            with open(output_file, "w", encoding="utf-8") as f:
                f.write("\n".join(current_file))
            current_part += 1
            current_file = []
            last_time = start_time
        
        current_file.append(f"{start_time:.1f} --> {end_time:.1f}: {text}")
        last_time = end_time

    # Write final part
    if current_file:
        output_file = os.path.join(output_dir, f"{base_filename}_part{current_part}.txt")
        with open(output_file, "w", encoding="utf-8") as f:
            f.write("\n".join(current_file))

    success(f"Split into {current_part} parts.")

def main():
    if len(sys.argv) != 4:
        info("Usage: python split_text.py <input_file> <output_dir> <base_filename>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_dir = sys.argv[2]
    base_filename = sys.argv[3]

    debug("split_text args:")
    debug(f"  Input file     : {input_file}")
    debug(f"  Output dir     : {output_dir}")
    debug(f"  Base filename  : {base_filename}")

    split_text(input_file, output_dir, base_filename)

if __name__ == "__main__":
    main()
