import os
import subprocess
import fnmatch

# ==========================================
# CONFIGURATION
# ==========================================
REPO_ROOT = "./"
OUTPUT_FILE = "codebase_context.md"

# 1. Skip files larger than this size (to prevent token explosion)
#    50KB is usually enough for source code. 
MAX_FILE_SIZE_BYTES = 50 * 1024 

# 2. Files to include (Only text-based extensions)
INCLUDE_EXTENSIONS = {
    ".py", ".js", ".ts", ".jsx", ".tsx", 
    ".html", ".css", ".scss", ".less",
    ".md", ".json", ".sql", ".yaml", ".yml", 
    ".toml", ".sh", ".dockerfile", ".r", ".go", ".rs", ".java", ".c", ".cpp"
}

# 3. Explicitly exclude these patterns (even if they are in Git)
#    Lockfiles are the usual culprit for 20k+ lines of noise.
EXCLUDE_PATTERNS = {
    "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "Gemfile.lock", 
    "poetry.lock", "composer.lock", "cargo.lock",
    "*.svg", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.ico",
    "data/*", "tests/*", "*test*", # Exclude tests if you want to save space
}
# ==========================================

def get_git_files(repo_root):
    """
    Get the list of all files tracked by git.
    """
    try:
        # Run git ls-files to get a clean list of tracked files
        result = subprocess.run(
            ["git", "ls-files"], 
            cwd=repo_root, 
            capture_output=True, 
            text=True, 
            check=True
        )
        # Split by newline and filter out empty strings
        files = [f for f in result.stdout.split('\n') if f.strip()]
        return files
    except subprocess.CalledProcessError:
        print("❌ Error: This directory is not a git repository.")
        return []
    except FileNotFoundError:
        print("❌ Error: 'git' command not found.")
        return []

def should_process_file(relpath):
    """
    Decides if a file should be included based on extension and exclusions.
    """
    # 1. Check Exclusion Patterns
    for pattern in EXCLUDE_PATTERNS:
        if fnmatch.fnmatch(relpath, pattern):
            return False

    # 2. Check Extension
    _, ext = os.path.splitext(relpath)
    if ext.lower() not in INCLUDE_EXTENSIONS:
        # Check specific filenames (like Dockerfile) that have no extension
        if os.path.basename(relpath) not in {"Dockerfile", "Makefile", "Jenkinsfile"}:
            return False

    return True

def get_tree_diagram(repo_root):
    """
    Generates tree diagram respecting gitignore using standard tree command.
    """
    # -I : Ignore .git folder
    # --gitignore : Filter out files listed in .gitignore (if tree version supports it)
    # --prune : Don't show empty branches
    # --noreport: Remove file count footer
    try:
        # Try using --gitignore flag (works on modern 'tree' versions)
        cmd = ["tree", repo_root, "-I", ".git", "--gitignore", "--prune", "--noreport", "-n"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        # Fallback for older tree versions that don't support --gitignore
        if result.returncode != 0:
            cmd = ["tree", repo_root, "-I", ".git|node_modules|venv|__pycache__", "--prune", "--noreport", "-n"]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
        return result.stdout
    except Exception as e:
        return f"Error generating tree: {e}"

def main():
    output_lines = []
    abs_root = os.path.abspath(REPO_ROOT)
    
    print(f"📍 Scanning Git Repo: {abs_root}")

    # 1. Header
    output_lines.append(f"# Project Context: {os.path.basename(abs_root)}\n")
    
    # 2. Tree Diagram
    print("🌳 Generating structure...")
    output_lines.append("## Project Structure\n")
    output_lines.append("```text")
    output_lines.append(get_tree_diagram(REPO_ROOT).strip())
    output_lines.append("\n```\n")

    # 3. File Contents (Based on Git)
    print("📄 Reading git files...")
    output_lines.append("## File Contents\n")
    
    git_files = get_git_files(REPO_ROOT)
    
    if not git_files:
        print("No git files found (or not a git repo). Exiting.")
        return

    count = 0
    skipped_size = 0

    for relpath in git_files:
        filepath = os.path.join(REPO_ROOT, relpath)
        
        # Check filters
        if not should_process_file(relpath):
            continue
            
        # Check file size
        try:
            file_size = os.path.getsize(filepath)
            if file_size > MAX_FILE_SIZE_BYTES:
                print(f"⚠️  Skipping large file: {relpath} ({file_size/1024:.1f} KB)")
                skipped_size += 1
                continue
        except OSError:
            continue

        print(f"   Including: {relpath}")
        count += 1
        
        try:
            with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
                
            ext = os.path.splitext(relpath)[1][1:] or "txt"
            
            output_lines.append(f"### File: `{relpath}`")
            output_lines.append(f"```{ext}")
            output_lines.append(content)
            output_lines.append("```\n")
            
        except Exception as e:
            print(f"   Error reading {relpath}: {e}")

    # Write Output
    full_content = "\n".join(output_lines)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(full_content)
    
    print(f"\n✅ Done! Processed {count} files. (Skipped {skipped_size} large files)")
    print(f"📂 Output: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
