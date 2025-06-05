import sys
import re
from utils.logging import debug, info, success

def anonymize(input_txt, output_txt):
    with open(input_txt, "r", encoding="utf-8") as f_in, open(output_txt, "w", encoding="utf-8") as f_out:
        speaker_count = {}
        for line in f_in:
            # Find speaker names (e.g., [Speaker1] Hello)
            match = re.match(r"\[(.*?)\]", line)
            if match:
                speaker = match.group(1)
                if speaker not in speaker_count:
                    speaker_count[speaker] = len(speaker_count) + 1
                anonymous_speaker = f"Speaker{speaker_count[speaker]}"
                line = line.replace(f"[{speaker}]", f"[{anonymous_speaker}]")
            f_out.write(line)

        debug("Speaker mapping:")
        for original, count in speaker_count.items():
            debug(f"  {original} -> Speaker{count}")

    success(f"Anonymized transcript saved to: {output_txt}")

def main():
    if len(sys.argv) != 3:
        info("Usage: python anonymize.py <input.txt> <output.txt>")
        sys.exit(1)

    input_txt = sys.argv[1]
    output_txt = sys.argv[2]

    anonymize(input_txt, output_txt)

if __name__ == "__main__":
    main()
