# Meeting Report Generation

An automated meeting report generation system that handles the entire process from voice recording transcription to report generation, including summarization and section organization.

## Features

- Voice recording transcription
- Meeting content summarization using LLM
- Executive summary generation
- Section-based summary and organization
- Report output in Word format

## Requirements

- Python 3.8 or higher
- llama.cpp
- Mixtral 8x7B Instruct model
- Word template file

## Setup

1. Install required Python packages:
```bash
pip install -r requirements.txt
```

2. Set up llama.cpp
3. Download Mixtral 8x7B model
4. Place template files

## Usage

Basic usage:
```bash
./run_meeting_report.sh <recording_file> <output_directory>
```

Debug mode:
```bash
# Full verbose mode
./run_meeting_report.sh <recording_file> <output_directory> --verbose

# Debug specific step
./run_meeting_report.sh <recording_file> <output_directory> --step <step_number>
```

Available steps:
1. Transcribing
2. Anonymizing
3. Splitting Text
4. LLM Summarizing
5. Creating DOCX
6. Extract Exec Summary
7. Summarize Exec Summary
8. Refine DOCX
9. Extract Key Discussion Points
10. Summarize Key Discussion Points
11. Refine DOCX (Key Discussion Points)
12. Extract Action Items and Next Steps
13. Summarize Action Items and Next Steps
14. Refine DOCX (Action Items and Next Steps)
15. Convert to PDF

## Directory Structure

- `MeetingRecordings/`: Meeting recording files
- `MeetingOutputs/`: Generated reports
- `Templates/`: Word templates
- `models/`: LLM models

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 