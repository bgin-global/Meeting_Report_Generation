#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <base_filename>"
    exit 1
fi

BASE_NAME="$1"
PROJECT_DIR="$(cd "$(dirname "$0")"; pwd)"
WORKING_DIR="$PROJECT_DIR/Working"
OUTPUT_DIR="$PROJECT_DIR/MeetingOutputs"
CHUNKS_DIR="$WORKING_DIR/${BASE_NAME}_chunks"
MODEL_PATH="$PROJECT_DIR/models/mixtral-8x7b-instruct-v0.1/mixtral-8x7b-instruct-v0.1.Q5_K_M.gguf"
LLAMA_RUN="$PROJECT_DIR/llama.cpp/build/bin/llama-run"
TEMPLATE_FILE="$PROJECT_DIR/template.docx"

# Execute only after Step 6

echo "== Step 6: Extract Exec Summary =="
python3 "$PROJECT_DIR/extract_exec_summary.py" "$WORKING_DIR/${BASE_NAME}_report.docx" "$WORKING_DIR/${BASE_NAME}_exec_summary.txt" || exit 1

echo "== Step 7: Summarize Exec Summary =="
python3 "$PROJECT_DIR/summarize_exec_summary.py" "$WORKING_DIR/${BASE_NAME}_exec_summary.txt" "$PROJECT_DIR/exec_summary_prompt.txt" "$WORKING_DIR/${BASE_NAME}_exec_summary_short.txt" "$LLAMA_RUN" "$MODEL_PATH" || exit 1

echo "== Step 8: Refine DOCX =="
python3 "$PROJECT_DIR/refine_exec_summary.py" "$WORKING_DIR/${BASE_NAME}_report.docx" "$WORKING_DIR/${BASE_NAME}_exec_summary_short.txt" "$OUTPUT_DIR/${BASE_NAME}_report.docx" || exit 1

echo "== Step 9: Convert to PDF =="
python3 "$PROJECT_DIR/convert_to_pdf.py" "$OUTPUT_DIR/${BASE_NAME}_report.docx" "$OUTPUT_DIR/${BASE_NAME}_report.pdf" || exit 1

echo "✅ Step6以降のみ完了。Output saved to $OUTPUT_DIR" 