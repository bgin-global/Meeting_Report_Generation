import sys
import os
import re
from docx import Document
from docx.shared import Pt
from utils.logging import debug, info, success, warning

# Mapping between placeholders and sections
PLACEHOLDER_MAP = {
    "<< EXEC_SUMMARY >>": "Executive Summary",
    "<< KEY_DISCUSSION >>": "Key Discussion Points",
    "<< ACTION_ITEMS >>": "Action Items and Next Steps",
    "<< DETAILED_SUMMARY >>": "Detailed Session Summary",
    "<< APPENDIX >>": "Appendix"
}

def clean_text(text):
    # Remove control characters not compatible with XML and ANSI codes (e.g., [0m)
    text = re.sub(r'\[\d+m', '', text)
    text = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F]', '', text)
    return text.strip()

def extract_sections(text):
    # Match both # Executive Summary and **Executive Summary**
    pattern = r"(?:#|\*\*)\s*(Executive Summary|Key Discussion Points|Action Items and Next Steps|Detailed Session Summary)\s*(?:\*\*)?"
    matches = list(re.finditer(pattern, text))
    
    sections = {}
    for i, match in enumerate(matches):
        start = match.end()
        end = matches[i+1].start() if i < len(matches)-1 else len(text)
        section_name = match.group(1)
        section_text = text[start:end].strip()
        sections[section_name] = section_text
    
    return sections

def create_report(input_dir, base_filename, output_docx, template_docx=None):
    # Initialize document
    doc = Document(template_docx) if template_docx else Document()
    
    # Read all parts
    all_sections = {}
    part_num = 1
    while True:
        part_file = os.path.join(input_dir, f"{base_filename}_part{part_num}_output.txt")
        if not os.path.exists(part_file):
            break
            
        with open(part_file, "r", encoding="utf-8") as f:
            text = f.read()
            sections = extract_sections(text)
            
            for name, content in sections.items():
                if name not in all_sections:
                    all_sections[name] = []
                all_sections[name].append(content)
        
        part_num += 1
    
    # Debug: Save all_sections content to file before docx output
    try:
        with open("debug_sections.txt", "w", encoding="utf-8") as debug_f:
            for name, contents in all_sections.items():
                debug_f.write(f"\n=== {name} ===\n")
                for i, content in enumerate(contents, 1):
                    debug_f.write(f"\n--- Part {i} ---\n{content}\n")
    except Exception as e:
        warning(f"Failed to write debug_sections.txt: {e}")
    
    # Replace placeholders with content
    for para in doc.paragraphs:
        for placeholder, section_name in PLACEHOLDER_MAP.items():
            if placeholder in para.text and section_name in all_sections:
                para.text = para.text.replace(placeholder, "\n".join(all_sections[section_name]))
    
    doc.save(output_docx)
    success(f"Final report saved to: {output_docx}")

def main():
    if len(sys.argv) != 5:
        info("Usage: python create_docx.py <input_dir> <base_filename> <output_file> <template_file>")
        sys.exit(1)
    
    input_dir = sys.argv[1]
    base_filename = sys.argv[2]
    output_docx = sys.argv[3]
    template_docx = sys.argv[4]
    
    create_report(input_dir, base_filename, output_docx, template_docx)

if __name__ == "__main__":
    main()
