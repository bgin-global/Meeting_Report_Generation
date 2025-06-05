import sys
import subprocess
import re
from utils.logging import debug, info, success, error

MAX_RECURSION = 5  # Maximum recursion depth

def clean_text(text):
    text = re.sub(r'\[\d+m', '', text)
    text = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F]', '', text)
    text = re.sub(r'\n{3,}', '\n\n', text)  # Reduce consecutive newlines to two
    text = re.sub(r' +', ' ', text)  # Reduce consecutive spaces to one
    return text.strip()

def build_prompt(section_name, section_text, max_chars=None):
    prompt = f"""Please summarize the following {section_name} section concisely while preserving all key information.
Focus on extracting and organizing the main points, action items, and important details.

{f'Please keep the summary under {max_chars} characters.' if max_chars else 'Please be concise but comprehensive.'}

=== BEGIN SECTION ===
{section_text}"""
    return prompt

def run_llm(command, input_text):
    debug(f"command: {' '.join(command)}")
    
    process = subprocess.run(
        command,
        input=input_text,
        capture_output=True,
        text=True
    )
    
    if process.returncode != 0:
        error("LLM execution failed.")
        error(process.stderr)
        return None
    
    output_text = process.stdout.strip()
    debug(f"output_text: {output_text}")
    return output_text

def recursive_summarize(text, llama_run_path, model_path, recursion_depth=0):
    if recursion_depth >= MAX_RECURSION:
        debug(f"Max recursion depth {MAX_RECURSION} reached. Returning as is.")
        return text
    
    # Split into chunks if text is too long
    chunks = text.split("\n\n")
    prev_num_chunks = len(chunks)
    
    debug(f"recursion_depth={recursion_depth}, {len(chunks)} chunks to summarize")
    
    if len(chunks) <= 1:
        return text
    
    if recursion_depth > 0 and len(chunks) >= prev_num_chunks:
        debug(f"Number of chunks did not decrease ({len(chunks)} >= {prev_num_chunks}). Breaking recursion.")
        return text
    
    # Summarize each chunk
    summarized_chunks = []
    for idx, chunk in enumerate(chunks):
        if not chunk.strip():
            continue
            
        debug(f"Summarizing chunk {idx+1}/{len(chunks)}")
        command = [
            llama_run_path,
            "--temp", "0.7",
            model_path,
            f"Please summarize this text concisely:\n\n{chunk}"
        ]
        
        result = run_llm(command, chunk)
        if result:
            summarized_chunks.append(result)
    
    # Combine summarized chunks
    combined = "\n\n".join(summarized_chunks)
    
    # Recursively summarize if still too long
    return recursive_summarize(combined, llama_run_path, model_path, recursion_depth + 1)

def main():
    if len(sys.argv) != 6:
        info("Usage: python summarize_section.py <section_name> <input.txt> <output.txt> <llama_run_path> <model_path>")
        sys.exit(1)

    section_name = sys.argv[1]
    input_txt = sys.argv[2]
    output_txt = sys.argv[3]
    llama_run_path = sys.argv[4]
    model_path = sys.argv[5]

    with open(input_txt, "r", encoding="utf-8") as f:
        text = f.read().strip()

    # Build prompt and run LLM
    prompt = build_prompt(section_name, text)
    command = [llama_run_path, "--temp", "0.7", model_path, prompt]
    
    result = run_llm(command, prompt)
    if result:
        with open(output_txt, "w", encoding="utf-8") as f:
            f.write(result)
        success(f"Condensed summary saved to: {output_txt}")

if __name__ == "__main__":
    main() 