import os
from docx import Document
from docx2pdf import convert

# ==== 設定セクション ====
OUTPUT_DIR = os.path.expanduser("~/MeetingReportProject/MeetingOutputs")

# DOCXファイルを探す
docx_files = [f for f in os.listdir(OUTPUT_DIR) if f.endswith(".docx")]

# PDF変換する
for docx_file in docx_files:
    docx_path = os.path.join(OUTPUT_DIR, docx_file)
    pdf_path = os.path.join(OUTPUT_DIR, os.path.splitext(docx_file)[0] + ".pdf")
    
    print(f"Converting {docx_file} to PDF...")
    convert(docx_path, pdf_path)

print("✅ All PDF conversions completed!")
