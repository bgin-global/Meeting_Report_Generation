import sys
import re
from docx import Document

def clean_text(text):
    text = re.sub(r'\[\d+m', '', text)
    text = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F]', '', text)
    return text.strip()

def extract_section(docx_path, section_name, output_txt_path):
    doc = Document(docx_path)
    start = False
    lines = []
    for para in doc.paragraphs:
        # セクション開始（部分一致・大文字小文字無視）
        if section_name.lower() in para.text.strip().lower():
            start = True
            continue
        # セクション終了（次のHeadingで止める）
        if start and para.style.name.startswith("Heading"):
            break
        if start:
            lines.append(para.text)
    full_text = clean_text("\n".join(lines).strip())
    with open(output_txt_path, "w", encoding="utf-8") as f:
        f.write(full_text)
    print(f"✅ Section '{section_name}' extracted to: {output_txt_path}")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python extract_section.py <input.docx> <section_name> <output.txt>")
        sys.exit(1)
    input_docx = sys.argv[1]
    section_name = sys.argv[2]
    output_txt = sys.argv[3]
    extract_section(input_docx, section_name, output_txt) 