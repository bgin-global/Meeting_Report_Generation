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
MODEL_PATH="$PROJECT_DIR/models/mixtral-8x7b-instruct-v0.1/mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf"
LLAMA_RUN="$PROJECT_DIR/llama.cpp/build/bin/llama-run"
TEMPLATE_FILE="$PROJECT_DIR/template.docx"

mkdir -p "$WORKING_DIR" "$OUTPUT_DIR" "$CHUNKS_DIR"

epoch_to_hms() {
    local SECONDS=$1
    printf '%02d:%02d:%02d' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60))
}

ALL_START=$(date +%s)

# Step 4: LLM Summarizing
STEP_START=$(date +%s)
echo "== Step 4: LLM Summarizing =="
for file in "$CHUNKS_DIR"/${BASE_NAME}_part*.txt; do
    if [[ "$file" == *_output.txt ]]; then
        continue
    fi
    chunk_out="${file%.txt}_output.txt"
    echo "Processing $file"
    python3 "$PROJECT_DIR/llama_runner.py" "$LLAMA_RUN" "$MODEL_PATH" "$file" || exit 1
done
STEP_END=$(date +%s)
STEP4_TIME=$((STEP_END - STEP_START))
echo "[Step 4] Elapsed time: $(epoch_to_hms $STEP4_TIME)"

# Step 5: Creating DOCX
STEP_START=$(date +%s)
echo "== Step 5: Creating DOCX =="
python3 "$PROJECT_DIR/create_docx.py" "$CHUNKS_DIR" "$BASE_NAME" "$WORKING_DIR/${BASE_NAME}_report.docx" "$TEMPLATE_FILE" || exit 1
STEP_END=$(date +%s)
STEP5_TIME=$((STEP_END - STEP_START))
echo "[Step 5] Elapsed time: $(epoch_to_hms $STEP5_TIME)"

# Step 6: Extract Exec Summary
STEP_START=$(date +%s)
echo "== Step 6: Extract Exec Summary =="
python3 "$PROJECT_DIR/extract_exec_summary.py" "$WORKING_DIR/${BASE_NAME}_report.docx" "$WORKING_DIR/${BASE_NAME}_exec_summary.txt" || exit 1
STEP_END=$(date +%s)
STEP6_TIME=$((STEP_END - STEP_START))
echo "[Step 6] Elapsed time: $(epoch_to_hms $STEP6_TIME)"

# Step 7: Summarize Exec Summary
STEP_START=$(date +%s)
echo "== Step 7: Summarize Exec Summary =="
python3 "$PROJECT_DIR/summarize_exec_summary.py" "$WORKING_DIR/${BASE_NAME}_exec_summary.txt" "$PROJECT_DIR/exec_summary_prompt.txt" "$WORKING_DIR/${BASE_NAME}_exec_summary_short.txt" "$LLAMA_RUN" "$MODEL_PATH" || exit 1
STEP_END=$(date +%s)
STEP7_TIME=$((STEP_END - STEP_START))
echo "[Step 7] Elapsed time: $(epoch_to_hms $STEP7_TIME)"

# Step 8: Refine DOCX
STEP_START=$(date +%s)
echo "== Step 8: Refine DOCX =="
python3 "$PROJECT_DIR/refine_exec_summary.py" "$WORKING_DIR/${BASE_NAME}_report.docx" "$WORKING_DIR/${BASE_NAME}_exec_summary_short.txt" "$OUTPUT_DIR/${BASE_NAME}_report.docx" || exit 1
STEP_END=$(date +%s)
STEP8_TIME=$((STEP_END - STEP_START))
echo "[Step 8] Elapsed time: $(epoch_to_hms $STEP8_TIME)"

# Step 9: Convert to PDF
STEP_START=$(date +%s)
echo "== Step 9: Convert to PDF =="
python3 "$PROJECT_DIR/convert_to_pdf.py" "$OUTPUT_DIR/${BASE_NAME}_report.docx" "$OUTPUT_DIR/${BASE_NAME}_report.pdf" || exit 1
STEP_END=$(date +%s)
STEP9_TIME=$((STEP_END - STEP_START))
echo "[Step 9] Elapsed time: $(epoch_to_hms $STEP9_TIME)"

# Step 10: Extract Key Discussion Points
STEP_START=$(date +%s)
echo "== Step 10: Extract Key Discussion Points =="
python3 "$PROJECT_DIR/extract_section.py" "$WORKING_DIR/${BASE_NAME}_report.docx" "Key Discussion Points" "$WORKING_DIR/${BASE_NAME}_key_discussion.txt" || exit 1
STEP_END=$(date +%s)
STEP10_TIME=$((STEP_END - STEP_START))
echo "[Step 10] Elapsed time: $(epoch_to_hms $STEP10_TIME)"

# Step 11: Summarize Key Discussion Points
STEP_START=$(date +%s)
echo "== Step 11: Summarize Key Discussion Points =="
echo "[DEBUG] LLAMA_RUN: $LLAMA_RUN"
echo "[DEBUG] MODEL_PATH: $MODEL_PATH"
echo "[DEBUG] Key Discussion Input: $WORKING_DIR/${BASE_NAME}_key_discussion.txt"
echo "[DEBUG] Key Discussion Output: $WORKING_DIR/${BASE_NAME}_key_discussion_condensed.txt"
python3 "$PROJECT_DIR/summarize_section.py" "Key Discussion Points" "$WORKING_DIR/${BASE_NAME}_key_discussion.txt" "$WORKING_DIR/${BASE_NAME}_key_discussion_condensed.txt" "$LLAMA_RUN" "$MODEL_PATH" || exit 1
STEP_END=$(date +%s)
STEP11_TIME=$((STEP_END - STEP_START))
echo "[Step 11] Elapsed time: $(epoch_to_hms $STEP11_TIME)"

# Step 12: Refine DOCX (Key Discussion Points)
STEP_START=$(date +%s)
echo "== Step 12: Refine DOCX (Key Discussion Points) =="
python3 "$PROJECT_DIR/refine_section.py" "$OUTPUT_DIR/${BASE_NAME}_report.docx" "Key Discussion Points" "$WORKING_DIR/${BASE_NAME}_key_discussion_condensed.txt" "$OUTPUT_DIR/${BASE_NAME}_report.docx" || exit 1
STEP_END=$(date +%s)
STEP12_TIME=$((STEP_END - STEP_START))
echo "[Step 12] Elapsed time: $(epoch_to_hms $STEP12_TIME)"

# Step 13: Extract Action Items and Next Steps
STEP_START=$(date +%s)
echo "== Step 13: Extract Action Items and Next Steps =="
python3 "$PROJECT_DIR/extract_section.py" "$WORKING_DIR/${BASE_NAME}_report.docx" "Action Items and Next Steps" "$WORKING_DIR/${BASE_NAME}_action_items.txt" || exit 1
STEP_END=$(date +%s)
STEP13_TIME=$((STEP_END - STEP_START))
echo "[Step 13] Elapsed time: $(epoch_to_hms $STEP13_TIME)"

# Step 14: Summarize Action Items and Next Steps
STEP_START=$(date +%s)
echo "== Step 14: Summarize Action Items and Next Steps =="
echo "[DEBUG] LLAMA_RUN: $LLAMA_RUN"
echo "[DEBUG] MODEL_PATH: $MODEL_PATH"
echo "[DEBUG] Action Items Input: $WORKING_DIR/${BASE_NAME}_action_items.txt"
echo "[DEBUG] Action Items Output: $WORKING_DIR/${BASE_NAME}_action_items_condensed.txt"
python3 "$PROJECT_DIR/summarize_section.py" "Action Items and Next Steps" "$WORKING_DIR/${BASE_NAME}_action_items.txt" "$WORKING_DIR/${BASE_NAME}_action_items_condensed.txt" "$LLAMA_RUN" "$MODEL_PATH" || exit 1
STEP_END=$(date +%s)
STEP14_TIME=$((STEP_END - STEP_START))
echo "[Step 14] Elapsed time: $(epoch_to_hms $STEP14_TIME)"

# Step 15: Refine DOCX (Action Items and Next Steps)
STEP_START=$(date +%s)
echo "== Step 15: Refine DOCX (Action Items and Next Steps) =="
python3 "$PROJECT_DIR/refine_section.py" "$OUTPUT_DIR/${BASE_NAME}_report.docx" "Action Items and Next Steps" "$WORKING_DIR/${BASE_NAME}_action_items_condensed.txt" "$OUTPUT_DIR/${BASE_NAME}_report.docx" || exit 1
STEP_END=$(date +%s)
STEP15_TIME=$((STEP_END - STEP_START))
echo "[Step 15] Elapsed time: $(epoch_to_hms $STEP15_TIME)"

ALL_END=$(date +%s)
ALL_TIME=$((ALL_END - ALL_START))
echo "[Total elapsed time] $(epoch_to_hms $ALL_TIME)"
echo "--- Stepwise elapsed time summary ---"
echo "Step 4: LLM Summarizing        $(epoch_to_hms $STEP4_TIME)"
echo "Step 5: Creating DOCX          $(epoch_to_hms $STEP5_TIME)"
echo "Step 6: Extract Exec Summary   $(epoch_to_hms $STEP6_TIME)"
echo "Step 7: Summarize Exec Summary $(epoch_to_hms $STEP7_TIME)"
echo "Step 8: Refine DOCX            $(epoch_to_hms $STEP8_TIME)"
echo "Step 9: Convert to PDF         $(epoch_to_hms $STEP9_TIME)"
echo "Step 10: Extract Key Discussion Points           $(epoch_to_hms $STEP10_TIME)"
echo "Step 11: Summarize Key Discussion Points         $(epoch_to_hms $STEP11_TIME)"
echo "Step 12: Refine DOCX (Key Discussion Points)     $(epoch_to_hms $STEP12_TIME)"
echo "Step 13: Extract Action Items and Next Steps     $(epoch_to_hms $STEP13_TIME)"
echo "Step 14: Summarize Action Items and Next Steps   $(epoch_to_hms $STEP14_TIME)"
echo "Step 15: Refine DOCX (Action Items and Next Steps) $(epoch_to_hms $STEP15_TIME)"
echo "✅ Step4 and after completed. Output saved to $OUTPUT_DIR" 