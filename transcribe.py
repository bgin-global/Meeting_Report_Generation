import sys
import os
import faster_whisper
from pathlib import Path
import subprocess
from utils.logging import debug, info, progress, success

def transcribe(input_wav, output_txt, model_size="large-v2"):
    if len(sys.argv) < 2:
        info("Usage: python transcribe.py <video_id> [model_size]")
        sys.exit(1)

    # Paths
    base_dir = Path(__file__).resolve().parent
    recordings_dir = base_dir / "MeetingRecordings"
    working_dir = base_dir / "Working"
    output_dir = base_dir / "MeetingOutputs"
    working_dir.mkdir(exist_ok=True)
    output_dir.mkdir(exist_ok=True)

    video_path = recordings_dir / f"{input_wav.stem}.mp4"
    wav_path = output_dir / f"{input_wav.stem}.wav"
    output_txt_path = working_dir / f"{input_wav.stem}_transcript.txt"

    # Extract audio to wav
    print(f"🔵 Extracting audio to WAV: {wav_path}")
    subprocess.run([
        "ffmpeg", "-y", "-i", str(video_path),
        "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le", str(wav_path)
    ], check=True)

    # Load model
    progress(f"Starting transcription for: {wav_path}")
    model = faster_whisper.WhisperModel(model_size, device="cuda", compute_type="float16")
    progress("Model loaded successfully.")

    # Transcribe
    debug("Running transcription...")
    segments, _ = model.transcribe(
        input_wav,
        beam_size=5,
        word_timestamps=True,
        condition_on_previous_text=True,
        initial_prompt="This is a meeting transcript."
    )

    # Write output
    segment_list = list(segments)  # Convert generator to list
    progress(f"Transcription completed. Now writing to {output_txt}")
    
    with open(output_txt, "w", encoding="utf-8") as f:
        for segment in segment_list:
            f.write(f"{segment.start:.1f} --> {segment.end:.1f}: {segment.text}\n")

    success(f"Transcription saved. {len(segment_list)} segments written.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        info("Usage: python transcribe.py <video_id> [model_size]")
        sys.exit(1)

    wav_path = sys.argv[1]
    model_size = sys.argv[2] if len(sys.argv) > 2 else "large-v2"
    output_txt_path = wav_path.replace(".wav", "_transcript.txt")

    transcribe(wav_path, output_txt_path, model_size)
