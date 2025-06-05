# llama_runner.py

import sys
import subprocess
import os
from utils.logging import debug, info, success, error

def run_llama(llama_run_path, model_path, input_file, output_file=None):
    if len(sys.argv) < 4:
        info("Usage: python llama_runner.py <llama_run_path> <model_path> <input_file>")
        sys.exit(1)

    # Debug information
    debug("sys.argv contents: " + str(sys.argv))
    debug("llama_runner.py called with:")
    debug(f"  llama_run_path: {llama_run_path}")
    debug(f"  model_path    : {model_path}")
    debug(f"  input_file    : {input_file}")

    # Save full prompt for debugging
    with open(input_file, "r", encoding="utf-8") as f:
        prompt = f.read()
    
    if os.environ.get('VERBOSE') == '1':
        debug_file = "debug_llama_prompt.txt"
        with open(debug_file, "w", encoding="utf-8") as f:
            f.write(prompt)
        debug(f"Full prompt saved to: {debug_file}")

    # Run llama.cpp
    command = [
        llama_run_path,
        "--temp", "0.7",
        "--ngl", "32",  # Run all layers on GPU
        "--context-size", "4096",
        "--verbose",  # Enable detailed logging
        model_path,
        prompt
    ]

    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    output, stderr = process.communicate()
    
    # Always display error output in verbose mode
    debug("llama-run stderr output: " + stderr)
    
    if process.returncode != 0:
        error("Error running llama-run: " + stderr)
        return None

    # Write output to file if specified
    if output_file:
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(output)
        success(f"Output written to: {output_file}")
    
    return output

if __name__ == "__main__":
    if len(sys.argv) != 4:
        info("Usage: python llama_runner.py <llama_run_path> <model_path> <input_file>")
        sys.exit(1)
    
    llama_run_path = sys.argv[1]
    model_path = sys.argv[2]
    input_file = sys.argv[3]
    
    run_llama(llama_run_path, model_path, input_file)
