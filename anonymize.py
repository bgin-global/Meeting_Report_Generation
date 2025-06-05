import sys
import os
import re

def anonymize(input_txt, output_txt):
    os.makedirs(os.path.dirname(output_txt), exist_ok=True)

    with open(input_txt, "r", encoding="utf-8") as f_in, open(output_txt, "w", encoding="utf-8") as f_out:
        speaker_count = {}
        for line in f_in:
            # スピーカー名を探す（例: [Speaker1] Hello）
            match = re.match(r"\[(.*?)\]", line)
            if match:
                speaker = match.group(1)
                if speaker not in speaker_count:
                    speaker_count[speaker] = f"Speaker{len(speaker_count)+1}"
                anon_speaker = speaker_count[speaker]
                line = line.replace(f"[{speaker}]", f"[{anon_speaker}]")
            f_out.write(line)

if __name__ == "__main__":
    input_txt = sys.argv[1]
    output_txt = sys.argv[2]
    anonymize(input_txt, output_txt)
