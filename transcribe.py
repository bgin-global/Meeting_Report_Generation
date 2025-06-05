import sys
import os
from faster_whisper import WhisperModel
from pathlib import Path
import subprocess

if len(sys.argv) < 2:
    print("Usage: python transcribe.py <video_id> [model_size]")
    sys.exit(1)

video_id = sys.argv[1]
model_size = sys.argv[2] if len(sys.argv) >= 3 else "medium"

# Paths
base_dir = Path(__file__).resolve().parent
recordings_dir = base_dir / "MeetingRecordings"
working_dir = base_dir / "Working"
output_dir = base_dir / "MeetingOutputs"
working_dir.mkdir(exist_ok=True)
output_dir.mkdir(exist_ok=True)

video_path = recordings_dir / f"{video_id}.mp4"
wav_path = output_dir / f"{video_id}.wav"
output_txt_path = working_dir / f"{video_id}_transcript.txt"

# Extract audio to wav
print(f"🔵 Extracting audio to WAV: {wav_path}")
subprocess.run([
    "ffmpeg", "-y", "-i", str(video_path),
    "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le", str(wav_path)
], check=True)

print(f"🔵 Starting transcription for: {wav_path}")
model = WhisperModel(model_size, device="auto", compute_type="auto")
print("🔵 Model loaded successfully.")

segments, _ = model.transcribe(
    str(wav_path),
    beam_size=1,
    vad_filter=True
)

segment_list = list(segments)  # cache generator

print(f"🔵 Transcription completed. Now writing to {output_txt_path}")

with open(output_txt_path, "w", encoding="utf-8") as f:
    for segment in segment_list:
        f.write(f"{segment.start:.2f} --> {segment.end:.2f}: {segment.text.strip()}\n")

print(f"✅ Transcription saved. {len(segment_list)} segments written.")
