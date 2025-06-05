import sys
import subprocess
import re
import math
import os

MAX_RECURSION = 5  # 再帰回数上限

def clean_text(text):
    text = re.sub(r'\[\d+m', '', text)
    text = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F]', '', text)
    text = re.sub(r'\n{3,}', '\n\n', text)  # Reduce consecutive newlines to two
    text = re.sub(r' +', ' ', text)  # Reduce consecutive spaces to one
    return text.strip()

def build_prompt(section_name, section_text, max_chars=None):
    limit_str = f"\nPlease summarize in no more than {max_chars} characters." if (max_chars and section_name != "Executive Summary") else ""
    if section_name == "Key Discussion Points":
        prompt = f"""You are a meeting summarizer.\n\nThe following is a collection of key discussion points from several meeting parts.\nPlease summarize them in detail, even if the summary becomes several pages long. Do NOT omit any important discussions or key points. It is critical that all essential arguments and decisions are preserved.\nUse clear, neutral language suitable for inclusion in a professional meeting report.{limit_str}\n\n--- BEGIN TEXT ---\n\n{section_text}\n\n--- END TEXT ---"""
    elif section_name == "Action Items and Next Steps":
        prompt = f"""You are a meeting summarizer.\n\nThe following is a collection of action items and next steps from several meeting parts.\nPlease summarize them in detail, even if the summary becomes several pages long. Do NOT omit any important actions or next steps. It is critical that all essential items and decisions are preserved.\nUse clear, neutral language suitable for inclusion in a professional meeting report.{limit_str}\n\n--- BEGIN TEXT ---\n\n{section_text}\n\n--- END TEXT ---"""
    elif section_name == "Executive Summary":
        prompt = f"""You are a meeting summarizer.\n\nThe following is an executive summary compiled from several meeting parts.\nPlease condense it into a single coherent summary suitable for a letter, aiming for about half a page and at most one page.\nUse clear, neutral language suitable for inclusion in a professional meeting report.\n\n--- BEGIN TEXT ---\n\n{section_text}\n\n--- END TEXT ---"""
    else:
        prompt = f"You are a meeting summarizer. Please condense the following section into a single coherent summary.{limit_str}\n\n--- BEGIN TEXT ---\n\n{section_text}\n\n--- END TEXT ---"
    return prompt

def run_llm(prompt, llama_run_path, model_path):
    command = [
        llama_run_path,
        model_path,
        '--ctx-size', '4096',
        '--threads', '4',
        '--temp', '0.3',
        '--ngl', '32'
    ]
    print(f"[summarize_section] command: {' '.join(command)}")
    result = subprocess.run(command, input=prompt.encode('utf-8'), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode != 0:
        print("❌ LLM execution failed.")
        print(result.stderr.decode())
        sys.exit(1)
    output_text = result.stdout.decode()
    print(f"[summarize_section] output_text: {output_text}")
    return output_text

def recursive_summarize(section_name, text, llama_run_path, model_path, max_chunk_size=4000, recursion_depth=0, prev_num_chunks=None):
    text = clean_text(text)
    if recursion_depth >= MAX_RECURSION:
        print(f"[recursive_summarize] Max recursion depth {MAX_RECURSION} reached. Returning as is.")
        return text
    if len(text) <= max_chunk_size:
        prompt = build_prompt(section_name, text)
        return run_llm(prompt, llama_run_path, model_path)
    # 分割
    chunks = [text[i:i+max_chunk_size] for i in range(0, len(text), max_chunk_size)]
    print(f"[recursive_summarize] recursion_depth={recursion_depth}, {len(chunks)} chunks to summarize")
    if prev_num_chunks is not None and len(chunks) >= prev_num_chunks:
        print(f"[recursive_summarize] Number of chunks did not decrease ({len(chunks)} >= {prev_num_chunks}). Breaking recursion.")
        merged = "\n".join(chunks)
        return merged
    chunk_summaries = []
    max_chars = max_chunk_size // 2 if section_name in ["Key Discussion Points", "Action Items and Next Steps"] else None
    for idx, chunk in enumerate(chunks):
        print(f"[recursive_summarize] Summarizing chunk {idx+1}/{len(chunks)}")
        prompt = build_prompt(section_name, chunk, max_chars=max_chars)
        summary = run_llm(prompt, llama_run_path, model_path)
        summary = clean_text(summary)
        chunk_summaries.append(summary)
    merged = "\n".join(chunk_summaries)
    # 再帰
    return recursive_summarize(section_name, merged, llama_run_path, model_path, max_chunk_size, recursion_depth+1, len(chunks))

if __name__ == "__main__":
    if len(sys.argv) != 6:
        print("Usage: python summarize_section.py <section_name> <input.txt> <output.txt> <llama_run_path> <model_path>")
        sys.exit(1)
    section_name = sys.argv[1]
    input_txt = sys.argv[2]
    output_txt = sys.argv[3]
    llama_run_path = sys.argv[4]
    model_path = sys.argv[5]
    
    with open(input_txt, "r", encoding="utf-8") as f:
        section_text = f.read()
    summary = recursive_summarize(section_name, section_text, llama_run_path, model_path, max_chunk_size=4000)
    with open(output_txt, "w", encoding="utf-8") as f:
        f.write(summary)
    print(f"✅ Condensed summary saved to: {output_txt}") 