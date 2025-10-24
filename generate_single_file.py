import os

# Customize this to your project root
REPO_ROOT = "./"
# Output file
OUTPUT_FILE = "flattened_repo.txt"
# File extensions to include
INCLUDE_EXTENSIONS = {".py"}

# Excluded directories (e.g., virtualenvs, git, etc.)
EXCLUDE_DIRS = {".git", "__pycache__", ".venv", "venv", "env", ".mypy_cache", ".pytest_cache"}

def should_include_file(filename):
    return any(filename.endswith(ext) for ext in INCLUDE_EXTENSIONS)

def walk_repo_and_flatten(repo_root):
    flattened_code = []

    for root, dirs, files in os.walk(repo_root):
        # Filter out unwanted directories
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]

        for file in files:
            filepath = os.path.join(root, file)
            relpath = os.path.relpath(filepath, start=os.path.abspath(repo_root))
            if should_include_file(file):
                print(f"Including file: {relpath}")
                try:
                    with open(filepath, "r", encoding="utf-8") as f:
                        content = f.read()
                except Exception as e:
                    content = f"[Could not read file: {e}]"

                header = f"\n\n{'=' * 80}\n# File: {relpath}\n{'=' * 80}\n"
                flattened_code.append(header + content)

    return "\n".join(flattened_code)

if __name__ == "__main__":
    code = walk_repo_and_flatten(REPO_ROOT)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as out_file:
        out_file.write(code)
    print(f"Flattened code written to {OUTPUT_FILE}")
