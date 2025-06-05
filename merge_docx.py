import sys
import os
import re
from docx import Document
from utils.logging import debug, info, success

def clean_text(text):
    # Remove control characters not supported in Word XML (e.g., NULL bytes)
    return re.sub(r"[\x00-\x08\x0B\x0C\x0E-\x1F]", "", text)

def merge_documents(input_dir, base_filename, output_file, template_file=None):
    # Use template if available, otherwise create an empty document
    if template_file and os.path.exists(template_file):
        merged_doc = Document(template_file)
    else:
        merged_doc = Document()

    part_num = 1
    while True:
        input_file = os.path.join(input_dir, f"{base_filename}_part{part_num}_output.txt")
        if not os.path.exists(input_file):
            break

        with open(input_file, "r", encoding="utf-8") as f:
            content = f.read()
            cleaned_content = clean_text(content)

        # Section title (Part number)
        merged_doc.add_paragraph(f"Part {part_num}", "Heading 2")

        # Format paragraphs into multiple lines (separate paragraphs with blank lines)
        for paragraph_text in cleaned_content.strip().split("\n\n"):
            paragraph = merged_doc.add_paragraph()
            paragraph.add_run(paragraph_text.strip())

        part_num += 1

    merged_doc.save(output_file)
    success(f"Merged document saved to {output_file}")

def main():
    if len(sys.argv) != 5:
        info("Usage: python merge_docx.py <input_dir> <base_filename> <output_file> <template_file>")
        sys.exit(1)

    input_dir = sys.argv[1]
    base_filename = sys.argv[2]
    output_file = sys.argv[3]
    template_file = sys.argv[4]

    merge_documents(input_dir, base_filename, output_file, template_file)

if __name__ == "__main__":
    main()
