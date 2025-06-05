# Project Handover Documentation

## Project Overview
- Python workflow for automatically generating "anonymized speaker transcripts" and "meeting reports (Word + PDF)" from Zoom meeting recordings (MP4).
- Utilizes LLM (llama.cpp/llama-run + Mixtral 8x7B Q4_K_M) and faster-whisper.
- Deployed on Mac Studio.

## Main Processing Flow
1. Audio to Text Conversion (faster-whisper)
2. Speaker Anonymization
3. Text Segmentation
4. LLM-based Summary for Each Part
5. Word Report Generation
6. Recursive Summarization of Each Section (Executive Summary, Key Discussion Points, Action Items)
7. PDF Conversion

## Key Scripts and Files
- `run_meeting_report.sh`: Overall workflow control
- `summarize_section.py`: Implementation of recursive summarization
- `create_docx.py`: Word report generation
- `extract_section.py`: Section extraction
- `refine_section.py`: Summary insertion into DOCX
- `llama_runner.py`: LLM execution wrapper (Metal GPU support)

## Technical Considerations and Solutions
- **Recursive Summarization**:
    - Split long text, summarize each chunk with LLM → merge → recursively summarize.
    - For Key Discussion Points and Action Items, specified "character limit" in prompts for better convergence.
    - Executive Summary converged well with just "summarize briefly" instruction, no character limit needed.
    - Implemented recursion limit and split count change check to prevent infinite loops.
- **Prompt Design**:
    - Adjusted compression ratio and summarization strategy for each section.
    - Balanced between information coverage and compression ratio.
- **LLM Execution Settings**:
    - Using Mixtral 8x7B Q4_K_M model
    - Metal (GPU) execution (-ngl 1)
    - Temperature: 0.7, top-p: 0.9, context size: 4096
    - Enhanced error handling (stderr output and return code verification)

## Directory Structure
```
.
├── MeetingRecordings/  # Input MP4 files
├── Working/            # Intermediate files
├── MeetingOutputs/     # Final output (DOCX, PDF)
├── models/            # LLM model files
│   └── mixtral-8x7b-instruct-v0.1/
│       └── mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf
└── llama.cpp/         # llama.cpp build
    └── build/bin/llama-run
```

## Future Improvements and TODOs
- Further prompt optimization
- Adjustment of summarization strategies per section
- LLM parameter tuning
- Enhancement of error handling and logging
- Workflow automated testing and CI implementation
- Metal execution stability monitoring

## Handover Notes
- Please refer to this document and key scripts for understanding past decisions and improvements when maintaining or enhancing the system.
- If you have additional questions or requests, please add them to the README or this file.
- If issues occur with LLM execution (especially GPU-related), you can temporarily switch to CPU execution using `-ngl 0`.

---

*(Reflects latest status as of June 2024)* 