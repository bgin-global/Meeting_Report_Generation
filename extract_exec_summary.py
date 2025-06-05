import re
import sys

def clean_text(text):
    text = re.sub(r'\[\d+m', '', text)
    text = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F]', '', text)
    return text.strip()

def extract_exec_summary(docx_path, output_txt_path):
    from docx import Document

    print(f"[extract_exec_summary] input docx: {docx_path}")
    doc = Document(docx_path)
    start = False
    lines = []

    for para in doc.paragraphs:
        print(f"[extract_exec_summary] paragraph: {para.text}")
        if para.text.strip().startswith("1. Executive Summary"):
            start = True
            continue
        if para.text.strip().startswith("1.1 Condensed Executive Summary"):
            break
        if start:
            lines.append(para.text)

    full_text = clean_text("\n".join(lines).strip())
    print(f"[extract_exec_summary] extracted text: {full_text}")
    print(f"[extract_exec_summary] output txt: {output_txt_path}")

    with open(output_txt_path, "w", encoding="utf-8") as f:
        f.write(full_text)

    print(f"✅ Executive Summary extracted to: {output_txt_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python extract_exec_summary.py <input.docx> <output.txt>")
        sys.exit(1)

    input_docx = sys.argv[1]
    output_txt = sys.argv[2]
    extract_exec_summary(input_docx, output_txt)
