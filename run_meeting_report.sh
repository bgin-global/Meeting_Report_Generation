#!/bin/bash

# ==== Setting section ====
VERBOSE=${VERBOSE:-0}  # Default to non-verbose mode
export VERBOSE  # Export for Python scripts

# Get project directory from environment variable or use current directory
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR=$(pwd)
    warning "PROJECT_DIR not set, using current directory: $PROJECT_DIR"
fi

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
debug() {
    if [ "$VERBOSE" = "1" ]; then
        echo -e "${BLUE}[DEBUG] $*${NC}"
    fi
}

info() {
    echo -e "$*"
}

success() {
    echo -e "${GREEN}✅ $*${NC}"
}

error() {
    echo -e "${RED}❌ $*${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

progress() {
    echo -e "${BLUE}🔵 $*${NC}"
}

# Time tracking functions
epoch_to_hms() {
    local T=$1
    printf "%02d:%02d:%02d" $(($T/3600)) $(($T%3600/60)) $(($T%60))
}

print_usage() {
    info "Usage: $0 [options] <video_id>"
    info "Options:"
    info "  --verbose              Enable verbose output"
    info "  --step N              Run verbose output only for step N (1-15)"
    info "  --project-dir DIR     Set project directory (default: current directory)"
    info "Environment variables:"
    info "  PROJECT_DIR           Set project directory (alternative to --project-dir)"
    info "Arguments:"
    info "  video_id             Input video file name (without .mp4 extension)"
    exit 1
}

# Parse command line arguments
VERBOSE_STEP=0
BASE_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=1
            shift
            ;;
        --step)
            if [[ $2 =~ ^[0-9]+$ ]] && [ $2 -ge 1 ] && [ $2 -le 15 ]; then
                VERBOSE_STEP=$2
                VERBOSE=1
                shift 2
            else
                error "Invalid step number: $2"
                print_usage
            fi
            ;;
        --project-dir)
            if [ -d "$2" ]; then
                PROJECT_DIR="$2"
                shift 2
            else
                error "Project directory does not exist: $2"
                print_usage
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
                error "Unknown argument: $1"
                print_usage
            fi
            ;;
    esac
done

if [ -z "$BASE_NAME" ]; then
    error "No video ID provided"
    print_usage
fi

# Directory setup
INPUT_DIR="$PROJECT_DIR/MeetingRecordings"
WORKING_DIR="$PROJECT_DIR/Working/$BASE_NAME"
OUTPUT_DIR="$PROJECT_DIR/MeetingOutputs"
TEMPLATE_FILE="$PROJECT_DIR/template.docx"

# Validate directory structure
for dir in "$INPUT_DIR" "$PROJECT_DIR"; do
    if [ ! -d "$dir" ]; then
        error "Required directory not found: $dir"
        error "Please ensure the project directory has the correct structure:"
        error "  PROJECT_DIR/"
        error "  ├── MeetingRecordings/    (for input videos)"
        error "  ├── Working/              (for temporary files)"
        error "  ├── MeetingOutputs/       (for output files)"
        error "  └── template.docx         (report template)"
        exit 1
    fi
done

if [ ! -f "$TEMPLATE_FILE" ]; then
    error "Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Check input file exists
if [ ! -f "$INPUT_DIR/${BASE_NAME}.mp4" ]; then
    error "Input file not found: $INPUT_DIR/${BASE_NAME}.mp4"
    exit 1
fi

# Create working directories
mkdir -p "$WORKING_DIR"
mkdir -p "$OUTPUT_DIR"

# Record start time
ALL_START=$(date +%s)

# Function to print step timing
print_step_time() {
    local step_num=$1
    local step_name=$2
    local elapsed_time=$3
    echo -e "${CYAN}⏱️  Step $step_num: $step_name completed in $(epoch_to_hms $elapsed_time)${NC}"
}

# ==== Step 1: Audio Extraction ====
step_header() {
    local step_num=$1
    local step_name=$2
    if [ "$VERBOSE" = "1" ] && { [ $VERBOSE_STEP -eq 0 ] || [ $VERBOSE_STEP -eq $step_num ]; }; then
        progress "== Step $step_num: $step_name =="
    else
        info "🔄 Step $step_num: $step_name"
    fi
}

STEP1_START=$(date +%s)
step_header 1 "Audio Extraction"
ffmpeg -y -i "$INPUT_DIR/${BASE_NAME}.mp4" -vn -ar 16000 -ac 1 "$WORKING_DIR/full.wav" 2>/dev/null
STEP1_END=$(date +%s)
STEP1_TIME=$((STEP1_END - STEP1_START))
print_step_time 1 "Audio Extraction" $STEP1_TIME

# ==== Step 2: Transcription ====
STEP2_START=$(date +%s)
step_header 2 "Transcription"
python3 "$PROJECT_DIR/transcribe.py" "$WORKING_DIR/full.wav" "$WORKING_DIR/full_transcript.txt"
STEP2_END=$(date +%s)
STEP2_TIME=$((STEP2_END - STEP2_START))
print_step_time 2 "Transcription" $STEP2_TIME

# ==== Step 3: Anonymization ====
STEP3_START=$(date +%s)
step_header 3 "Anonymization"
python3 "$PROJECT_DIR/anonymize.py" "$WORKING_DIR/full_transcript.txt" "$WORKING_DIR/anonymized.txt"
STEP3_END=$(date +%s)
STEP3_TIME=$((STEP3_END - STEP3_START))
print_step_time 3 "Anonymization" $STEP3_TIME

# ... [Similar pattern for other steps] ...

# Record end time and print summary
ALL_END=$(date +%s)
ALL_TIME=$((ALL_END - ALL_START))

# Always print the timing summary table
echo -e "\n${CYAN}=== Execution Time Summary ===${NC}"
printf "${CYAN}%-40s %10s${NC}\n" "Step" "Duration"
printf "${CYAN}%-40s %10s${NC}\n" "----------------------------------------" "----------"
printf "%-40s %10s\n" "1. Audio Extraction" "$(epoch_to_hms $STEP1_TIME)"
printf "%-40s %10s\n" "2. Transcription" "$(epoch_to_hms $STEP2_TIME)"
printf "%-40s %10s\n" "3. Anonymization" "$(epoch_to_hms $STEP3_TIME)"
# ... [Add other steps] ...
printf "${CYAN}%-40s %10s${NC}\n" "----------------------------------------" "----------"
printf "${CYAN}%-40s %10s${NC}\n" "Total Execution Time" "$(epoch_to_hms $ALL_TIME)"

success "All steps completed successfully"
info "📄 Output files:"
info "   - Report: $OUTPUT_DIR/${BASE_NAME}_report.docx"
info "   - PDF: $OUTPUT_DIR/${BASE_NAME}_report.pdf"
