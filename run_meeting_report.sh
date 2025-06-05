#!/bin/bash

print_usage() {
    echo "Usage: $0 <base_filename> [options]"
    echo "Options:"
    echo "  --verbose         Enable verbose output"
    echo "  --step <number>   Run with verbose output for specific step (1-15)"
    exit 1
}

# Parse command line arguments
VERBOSE=false
VERBOSE_STEP=0
BASE_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --step)
            if [[ $2 =~ ^[0-9]+$ ]] && [ $2 -ge 1 ] && [ $2 -le 15 ]; then
                VERBOSE_STEP=$2
                VERBOSE=true
                shift 2
            else
                echo "Error: Step number must be between 1 and 15"
                exit 1
            fi
            ;;
        -h|--help)
            print_usage
            ;;
        *)
            if [ -z "$BASE_NAME" ]; then
                BASE_NAME="$1"
                shift
            else
                echo "Error: Unexpected argument '$1'"
                print_usage
            fi
            ;;
    esac
done

if [ -z "$BASE_NAME" ]; then
    echo "Error: Base filename is required"
    print_usage
fi

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

log_verbose() {
    if $VERBOSE && { [ $VERBOSE_STEP -eq 0 ] || [ $VERBOSE_STEP -eq $1 ]; }; then
        echo "$2"
    fi
}

log_step_start() {
    local step_num=$1
    local step_name=$2
    if $VERBOSE && { [ $VERBOSE_STEP -eq 0 ] || [ $VERBOSE_STEP -eq $step_num ]; }; then
        echo "== Step $step_num: $step_name =="
    else
        echo "🔄 Step $step_num: $step_name"
    fi
}

log_step_end() {
    local step_num=$1
    local step_name=$2
    local elapsed_time=$3
    if ! $VERBOSE || { [ $VERBOSE_STEP -ne 0 ] && [ $VERBOSE_STEP -ne $step_num ]; }; then
        echo "✅ Step $step_num completed ($(epoch_to_hms $elapsed_time))"
    fi
}

ALL_START=$(date +%s)

# Step 1
STEP_START=$(date +%s)
log_step_start 1 "Transcribing"
python3 "$PROJECT_DIR/transcribe.py" "$BASE_NAME" || exit 1
STEP_END=$(date +%s)
STEP1_TIME=$((STEP_END - STEP_START))
log_step_end 1 "Transcribing" $STEP1_TIME

# Step 2
STEP_START=$(date +%s)
log_step_start 2 "Anonymizing"
python3 "$PROJECT_DIR/anonymize.py" "$WORKING_DIR/${BASE_NAME}_transcript.txt" "$WORKING_DIR/${BASE_NAME}_anonymized.txt" || exit 1
STEP_END=$(date +%s)
STEP2_TIME=$((STEP_END - STEP_START))
log_step_end 2 "Anonymizing" $STEP2_TIME

# Step 3
STEP_START=$(date +%s)
log_step_start 3 "Splitting Text"
python3 "$PROJECT_DIR/split_text.py" "$WORKING_DIR/${BASE_NAME}_anonymized.txt" "$CHUNKS_DIR" "$BASE_NAME" || exit 1
STEP_END=$(date +%s)
STEP3_TIME=$((STEP_END - STEP_START))
log_step_end 3 "Splitting Text" $STEP3_TIME

# Step 4
STEP_START=$(date +%s)
log_step_start 4 "LLM Summarizing"
for file in "$CHUNKS_DIR"/${BASE_NAME}_part*.txt; do
    if [[ "$file" == *_output.txt ]]; then
        continue
    fi
    log_verbose 4 "Processing $file"
    python3 "$PROJECT_DIR/llama_runner.py" "$LLAMA_RUN" "$MODEL_PATH" "$file" || exit 1
done
STEP_END=$(date +%s)
STEP4_TIME=$((STEP_END - STEP_START))
log_step_end 4 "LLM Summarizing" $STEP4_TIME

# Step 5
STEP_START=$(date +%s)
log_step_start 5 "Creating DOCX"
python3 "$PROJECT_DIR/create_docx.py" "$CHUNKS_DIR" "$BASE_NAME" "$WORKING_DIR/${BASE_NAME}_report.docx" "$TEMPLATE_FILE" || exit 1
STEP_END=$(date +%s)
STEP5_TIME=$((STEP_END - STEP_START))
log_step_end 5 "Creating DOCX" $STEP5_TIME

# Step 6
STEP_START=$(date +%s)
log_step_start 6 "Extract Exec Summary"
python3 "$PROJECT_DIR/extract_exec_summary.py" "$WORKING_DIR/${BASE_NAME}_report.docx" "$WORKING_DIR/${BASE_NAME}_exec_summary.txt" || exit 1
STEP_END=$(date +%s)
STEP6_TIME=$((STEP_END - STEP_START))
log_step_end 6 "Extract Exec Summary" $STEP6_TIME

# Step 7
STEP_START=$(date +%s)
log_step_start 7 "Summarize Exec Summary"
python3 "$PROJECT_DIR/summarize_exec_summary.py" "$WORKING_DIR/${BASE_NAME}_exec_summary.txt" "$PROJECT_DIR/exec_summary_prompt.txt" "$WORKING_DIR/${BASE_NAME}_exec_summary_short.txt" "$LLAMA_RUN" "$MODEL_PATH" || exit 1
STEP_END=$(date +%s)
STEP7_TIME=$((STEP_END - STEP_START))
log_step_end 7 "Summarize Exec Summary" $STEP7_TIME

# Step 8
STEP_START=$(date +%s)
log_step_start 8 "Refine DOCX"
python3 "$PROJECT_DIR/refine_exec_summary.py" "$WORKING_DIR/${BASE_NAME}_report.docx" "$WORKING_DIR/${BASE_NAME}_exec_summary_short.txt" "$OUTPUT_DIR/${BASE_NAME}_report.docx" || exit 1
STEP_END=$(date +%s)
STEP8_TIME=$((STEP_END - STEP_START))
log_step_end 8 "Refine DOCX" $STEP8_TIME

# Step 9
STEP_START=$(date +%s)
log_step_start 9 "Extract Key Discussion Points"
python3 "$PROJECT_DIR/extract_section.py" "$WORKING_DIR/${BASE_NAME}_report.docx" "Key Discussion Points" "$WORKING_DIR/${BASE_NAME}_key_discussion.txt" || exit 1
STEP_END=$(date +%s)
STEP9_TIME=$((STEP_END - STEP_START))
log_step_end 9 "Extract Key Discussion Points" $STEP9_TIME

# Step 10
STEP_START=$(date +%s)
log_step_start 10 "Summarize Key Discussion Points"
log_verbose 10 "[DEBUG] Key Discussion Input: $WORKING_DIR/${BASE_NAME}_key_discussion.txt"
log_verbose 10 "[DEBUG] Key Discussion Output: $WORKING_DIR/${BASE_NAME}_key_discussion_condensed.txt"
python3 "$PROJECT_DIR/summarize_section.py" "Key Discussion Points" "$WORKING_DIR/${BASE_NAME}_key_discussion.txt" "$WORKING_DIR/${BASE_NAME}_key_discussion_condensed.txt" "$LLAMA_RUN" "$MODEL_PATH" || exit 1
STEP_END=$(date +%s)
STEP10_TIME=$((STEP_END - STEP_START))
log_step_end 10 "Summarize Key Discussion Points" $STEP10_TIME

# Step 11
STEP_START=$(date +%s)
log_step_start 11 "Refine DOCX (Key Discussion Points)"
python3 "$PROJECT_DIR/refine_section.py" "$OUTPUT_DIR/${BASE_NAME}_report.docx" "Key Discussion Points" "$WORKING_DIR/${BASE_NAME}_key_discussion_condensed.txt" "$OUTPUT_DIR/${BASE_NAME}_report.docx" || exit 1
STEP_END=$(date +%s)
STEP11_TIME=$((STEP_END - STEP_START))
log_step_end 11 "Refine DOCX (Key Discussion Points)" $STEP11_TIME

# Step 12
STEP_START=$(date +%s)
log_step_start 12 "Extract Action Items and Next Steps"
python3 "$PROJECT_DIR/extract_section.py" "$WORKING_DIR/${BASE_NAME}_report.docx" "Action Items and Next Steps" "$WORKING_DIR/${BASE_NAME}_action_items.txt" || exit 1
STEP_END=$(date +%s)
STEP12_TIME=$((STEP_END - STEP_START))
log_step_end 12 "Extract Action Items and Next Steps" $STEP12_TIME

# Step 13
STEP_START=$(date +%s)
log_step_start 13 "Summarize Action Items and Next Steps"
log_verbose 13 "[DEBUG] Action Items Input: $WORKING_DIR/${BASE_NAME}_action_items.txt"
log_verbose 13 "[DEBUG] Action Items Output: $WORKING_DIR/${BASE_NAME}_action_items_condensed.txt"
python3 "$PROJECT_DIR/summarize_section.py" "Action Items and Next Steps" "$WORKING_DIR/${BASE_NAME}_action_items.txt" "$WORKING_DIR/${BASE_NAME}_action_items_condensed.txt" "$LLAMA_RUN" "$MODEL_PATH" || exit 1
STEP_END=$(date +%s)
STEP13_TIME=$((STEP_END - STEP_START))
log_step_end 13 "Summarize Action Items and Next Steps" $STEP13_TIME

# Step 14
STEP_START=$(date +%s)
log_step_start 14 "Refine DOCX (Action Items and Next Steps)"
python3 "$PROJECT_DIR/refine_section.py" "$OUTPUT_DIR/${BASE_NAME}_report.docx" "Action Items and Next Steps" "$WORKING_DIR/${BASE_NAME}_action_items_condensed.txt" "$OUTPUT_DIR/${BASE_NAME}_report.docx" || exit 1
STEP_END=$(date +%s)
STEP14_TIME=$((STEP_END - STEP_START))
log_step_end 14 "Refine DOCX (Action Items and Next Steps)" $STEP14_TIME

# Step 15
STEP_START=$(date +%s)
log_step_start 15 "Convert to PDF"
python3 "$PROJECT_DIR/convert_to_pdf.py" "$OUTPUT_DIR/${BASE_NAME}_report.docx" "$OUTPUT_DIR/${BASE_NAME}_report.pdf" || exit 1
STEP_END=$(date +%s)
STEP15_TIME=$((STEP_END - STEP_START))
log_step_end 15 "Convert to PDF" $STEP15_TIME

ALL_END=$(date +%s)
ALL_TIME=$((ALL_END - ALL_START))

if $VERBOSE; then
    echo "--- Stepwise elapsed time summary ---"
    echo "Step 1: Transcribing           $(epoch_to_hms $STEP1_TIME)"
    echo "Step 2: Anonymizing            $(epoch_to_hms $STEP2_TIME)"
    echo "Step 3: Splitting Text         $(epoch_to_hms $STEP3_TIME)"
    echo "Step 4: LLM Summarizing        $(epoch_to_hms $STEP4_TIME)"
    echo "Step 5: Creating DOCX          $(epoch_to_hms $STEP5_TIME)"
    echo "Step 6: Extract Exec Summary   $(epoch_to_hms $STEP6_TIME)"
    echo "Step 7: Summarize Exec Summary $(epoch_to_hms $STEP7_TIME)"
    echo "Step 8: Refine DOCX           $(epoch_to_hms $STEP8_TIME)"
    echo "Step 9: Extract Key Discussion Points           $(epoch_to_hms $STEP9_TIME)"
    echo "Step 10: Summarize Key Discussion Points        $(epoch_to_hms $STEP10_TIME)"
    echo "Step 11: Refine DOCX (Key Discussion Points)    $(epoch_to_hms $STEP11_TIME)"
    echo "Step 12: Extract Action Items and Next Steps    $(epoch_to_hms $STEP12_TIME)"
    echo "Step 13: Summarize Action Items and Next Steps  $(epoch_to_hms $STEP13_TIME)"
    echo "Step 14: Refine DOCX (Action Items and Next Steps) $(epoch_to_hms $STEP14_TIME)"
    echo "Step 15: Convert to PDF        $(epoch_to_hms $STEP15_TIME)"
fi

echo "✨ All steps completed in $(epoch_to_hms $ALL_TIME)"
echo "📄 Output saved to:"
echo "   - DOCX: $OUTPUT_DIR/${BASE_NAME}_report.docx"
echo "   - PDF:  $OUTPUT_DIR/${BASE_NAME}_report.pdf"
