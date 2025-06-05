# ファイル名: merge_parts_to_docx.py

import os
from docx import Document

def merge_parts(input_dir, base_filename, output_file):
    merged_doc = Document()
    part_idx = 1

    while True:
        part_filename = f"{base_filename}_part{part_idx}_llm_output.txt"
        part_path = os.path.join(input_dir, part_filename)

        if not os.path.exists(part_path):
            break

        with open(part_path, 'r', encoding='utf-8') as f:
            text = f.read()

        # Allow only XML-compatible characters
        text = ''.join(c for c in text if c.isprintable() and c not in '\x00\x01\x02\x03\x04\x05\x06\x07\x08\x0b\x0c\x0e\x0f')

        merged_doc.add_paragraph(text)
        merged_doc.add_page_break()
        part_idx += 1

    merged_doc.save(output_file)

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 4:
        print("Usage: python merge_parts_to_docx.py <input_dir> <base_filename> <output_file>")
        sys.exit(1)

    input_dir = sys.argv[1]
    base_filename = sys.argv[2]
    output_file = sys.argv[3]

    merge_parts(input_dir, base_filename, output_file)
