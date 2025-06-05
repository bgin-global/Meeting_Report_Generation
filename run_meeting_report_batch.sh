#!/bin/bash

# ==== Setting section ====
INPUT_DIR="$HOME/MeetingReportProject/MeetingRecordings"
OUTPUT_DIR="$HOME/MeetingReportProject/MeetingOutputs"
WORK_DIR="$HOME/MeetingReportProject/Working"
LLAMA_RUN="$HOME/llama.cpp/build/bin/llama-run"
MODEL_PATH="$HOME/models/mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf"
PROMPT_FILE="$HOME/MeetingReportProject/prompt.txt"
MERGE_SCRIPT="$HOME/MeetingReportProject/merge_docx.py"

# Accept filename (without extension) as argument
FILENAME="$1"

# Check
if [ -z "$FILENAME" ]; then
  echo "Error: Please provide the mp4 filename (without extension)."
  exit 1
fi

# ==== Step 1: Setting up working directories ====
echo "Setting up working directories..."
mkdir -p "$WORK_DIR/$FILENAME"

# ==== Step 2: Extracting audio ====
echo "Extracting audio from ${FILENAME}.mp4..."
ffmpeg -y -i "$INPUT_DIR/${FILENAME}.mp4" -vn -ar 16000 -ac 1 "$WORK_DIR/$FILENAME/full.wav"

# ==== Step 3: Transcription ====
echo "Transcribing audio to text..."
python3 "$HOME/MeetingReportProject/transcribe.py" "$WORK_DIR/$FILENAME/full.wav" "$WORK_DIR/$FILENAME/full_transcript.txt"

# ==== Step 4: Anonymizing speaker names ====
echo "Anonymizing speaker names..."
python3 "$HOME/MeetingReportProject/anonymize.py" "$WORK_DIR/$FILENAME/full_transcript.txt" "$WORK_DIR/$FILENAME/full_anon.txt"

# ==== Step 5: Splitting transcript into parts ====
echo "Splitting transcript into parts (approx. every 45 min)..."
python3 "$HOME/MeetingReportProject/split_text.py" "$WORK_DIR/$FILENAME/full_anon.txt" "$WORK_DIR/$FILENAME/part" 18000

# ==== Step 6: Generate report for each part using Mixtral ====
echo "Generating meeting report parts with LLM..."
PART_FILES=("$WORK_DIR/$FILENAME"/part*.txt)
PART_INDEX=1

for PART_FILE in "${PART_FILES[@]}"
  do
    echo "Processing $PART_FILE..."
    TMP_PROMPT_FILE="$WORK_DIR/$FILENAME/tmp_prompt_part${PART_INDEX}.txt"
    cat "$PROMPT_FILE" "$PART_FILE" > "$TMP_PROMPT_FILE"

    $LLAMA_RUN "$MODEL_PATH" "$(cat $TMP_PROMPT_FILE)" --ctx-size 8192 --threads 8 --temp 0.3 > "$WORK_DIR/$FILENAME/part${PART_INDEX}_llm_output.txt"

    python3 "$HOME/MeetingReportProject/create_docx.py" "$WORK_DIR/$FILENAME/part${PART_INDEX}_llm_output.txt" "$WORK_DIR/$FILENAME/part${PART_INDEX}.docx"
    PART_INDEX=$((PART_INDEX+1))
  done

# ==== Step 7: DOCX integration ====
echo "Merging Word documents..."
python3 "$MERGE_SCRIPT" "$WORK_DIR/$FILENAME" "$OUTPUT_DIR/${FILENAME}.docx"

# ==== Step 8: PDF conversion ====
echo "Converting merged Word document to PDF..."
docx2pdf "$OUTPUT_DIR/${FILENAME}.docx" "$OUTPUT_DIR/${FILENAME}.pdf"

echo "✅ All done! Output files are in ${OUTPUT_DIR}"
