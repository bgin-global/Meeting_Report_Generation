from huggingface_hub import snapshot_download

snapshot_download(
    repo_id="TheBloke/Mixtral-8x7B-Instruct-v0.1-GGUF",
    local_dir="../models/Mixtral",
    local_dir_use_symlinks=False
)