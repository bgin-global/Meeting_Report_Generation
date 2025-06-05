import os

def is_verbose():
    """Check if verbose mode is enabled via environment variable."""
    return os.environ.get('VERBOSE', '0') == '1'

def debug(message):
    """Print debug message only in verbose mode."""
    if is_verbose():
        print(f"[DEBUG] {message}")

def info(message):
    """Print informational message."""
    print(message)

def success(message):
    """Print success message with checkmark."""
    print(f"✅ {message}")

def error(message):
    """Print error message with cross mark."""
    print(f"❌ {message}")

def progress(message):
    """Print progress message with blue dot."""
    print(f"🔵 {message}")

def warning(message):
    """Print warning message."""
    print(f"[Warning] {message}") 