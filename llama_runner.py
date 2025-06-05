# llama_runner.py

import sys
import subprocess
import os

if len(sys.argv) != 4:
    print("Usage: python llama_runner.py <llama_run_path> <model_path> <input_file>")
    sys.exit(1)

llama_run_path = sys.argv[1]
model_path = sys.argv[2]
input_file = sys.argv[3]

print("\u2705 sys.argv contents:", sys.argv)
print("\U0001F50D llama_runner.py called with:")
print("  llama_run_path:", llama_run_path)
print("  model_path    :", model_path)
print("  input_file    :", input_file)

# Read the input transcript
with open(input_file, 'r') as f:
    transcript = f.read()

# Prompt template
prompt = f"""You are an assistant tasked with producing a structured meeting report based on the following transcript.

Please generate a report with the following clearly labeled sections:

1. Executive Summary
2. Key Discussion Points
3. Action Items and Next Steps
4. Detailed Session Summary

Use bullet points where appropriate and preserve important technical terms. Maintain a professional and neutral tone.

=== BEGIN TRANSCRIPT ===\n{transcript}"""

# デバッグ用: llama-runに渡すprompt全文を保存
with open("debug_llama_prompt.txt", "w", encoding="utf-8") as debug_f:
    debug_f.write(prompt)

# Run llama-run with Metal (GPU)
cmd = [
    llama_run_path,
    "--temp", "0.7",
    "--ngl", "32",  # すべてのレイヤーをGPUで実行
    "--context-size", "4096",
    "--verbose",  # 詳細なログ出力を有効化
    model_path,
    prompt
]

output_file = input_file.replace(".txt", "_output.txt")

with open(output_file, 'w') as out_file:
    process = subprocess.Popen(
        cmd,
        stdout=out_file,
        stderr=subprocess.PIPE,
        text=True
    )
    _, stderr = process.communicate()
    
    # エラー出力を常に表示（デバッグ用）
    print("llama-run stderr output:", stderr)
    
    if process.returncode != 0:
        print("Error running llama-run:", stderr)
        sys.exit(1)

print(f"✅ Output written to: {output_file}")
