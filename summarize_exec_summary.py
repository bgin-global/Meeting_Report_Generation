import subprocess
import sys
import os
import re
import math

def clean_text(text):
    text = re.sub(r'\[\d+m', '', text)
    text = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F]', '', text)
    return text.strip()

def build_prompt(summary):
    prompt = f"""You are a meeting summarizer.\n\nThe following is a long executive summary compiled from several sessions.\nPlease condense it into a single coherent executive summary under 250 words.\nUse clear, neutral language suitable for inclusion in a professional meeting report.\n\n--- BEGIN TEXT ---\n\n{summary}\n\n--- END TEXT ---"""
    return prompt

def run_llm(prompt, llama_path, model_path):
    command = [
        llama_path,
        model_path,
        '--ctx-size', '4096',
        '--threads', '4',
        '--temp', '0.3',
        '--ngl', '99'
    ]
    print(f"[summarize_exec_summary] command: {' '.join(command)}")
    result = subprocess.run(command, input=prompt.encode('utf-8'), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode != 0:
        print("❌ LLM execution failed.")
        print(result.stderr.decode())
        sys.exit(1)
    output_text = result.stdout.decode()
    print(f"[summarize_exec_summary] output_text: {output_text}")
    return output_text

def recursive_summarize(text, llama_path, model_path, max_chunk_size=4000):
    text = clean_text(text)
    if len(text) <= max_chunk_size:
        prompt = build_prompt(text)
        return run_llm(prompt, llama_path, model_path)
    # 分割
    chunks = [text[i:i+max_chunk_size] for i in range(0, len(text), max_chunk_size)]
    print(f"[recursive_summarize] {len(chunks)} chunks to summarize")
    chunk_summaries = []
    for idx, chunk in enumerate(chunks):
        print(f"[recursive_summarize] Summarizing chunk {idx+1}/{len(chunks)}")
        prompt = build_prompt(chunk)
        summary = run_llm(prompt, llama_path, model_path)
        chunk_summaries.append(summary)
    merged = "\n".join(chunk_summaries)
    # 再帰
    return recursive_summarize(merged, llama_path, model_path, max_chunk_size)

if __name__ == "__main__":
    if len(sys.argv) != 6:
        print("Usage: python summarize_exec_summary.py <input_summary.txt> <prompt.txt> <output_summary.txt> <llama_run_path> <model_path>")
        sys.exit(1)

    input_summary = sys.argv[1]
    prompt_file = sys.argv[2]  # unused in new logic
    output_summary = sys.argv[3]
    llama_run_path = sys.argv[4]
    model_path = sys.argv[5]

    with open(input_summary, "r", encoding="utf-8") as f:
        summary_text = f.read()
    summary = recursive_summarize(summary_text, llama_run_path, model_path, max_chunk_size=4000)
    with open(output_summary, "w", encoding="utf-8") as f:
        f.write(summary)
    print(f"✅ Condensed summary saved to: {output_summary}")
