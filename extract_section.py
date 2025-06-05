import sys
from docx import Document
from utils.logging import debug, info, success

def extract_section(docx_path, section_name, output_txt_path):
    doc = Document(docx_path)
    start = False
    full_text = []

    for para in doc.paragraphs:
        if section_name in para.text:
            start = True
            continue
        if start:
            # Section ends (stops at next Heading)
            if para.style.name.startswith("Heading"):
                break
            full_text.append(para.text)

    with open(output_txt_path, "w", encoding="utf-8") as f:
        f.write("\n".join(full_text))

    success(f"Section '{section_name}' extracted to: {output_txt_path}")

def main():
    if len(sys.argv) != 4:
        info("Usage: python extract_section.py <input.docx> <section_name> <output.txt>")
        sys.exit(1)

    docx_path = sys.argv[1]
    section_name = sys.argv[2]
    output_txt_path = sys.argv[3]

    extract_section(docx_path, section_name, output_txt_path)

if __name__ == "__main__":
    main() 