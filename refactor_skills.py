import os
import re
import yaml

# Standard keys according to your requested configuration
ALLOWED_KEYS = {
    'name', 
    'description', 
    'license', 
    'compatibility', 
    'metadata', 
    'allowed-tools'
}

def refactor_skill_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Match YAML frontmatter between the first two sets of ---
    match = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
    if not match:
        print(f"Skipping {file_path}: No frontmatter found.")
        return

    frontmatter_raw = match.group(1)
    body = content[match.end():]

    try:
        # Using SafeLoader for security
        data = yaml.safe_load(frontmatter_raw)
    except yaml.YAMLError as exc:
        print(f"Error parsing YAML in {file_path}: {exc}")
        return

    if not isinstance(data, dict):
        print(f"Skipping {file_path}: Frontmatter is not a dictionary.")
        return

    # Extract existing metadata or initialize new dict
    metadata = data.pop('metadata', {})
    if not isinstance(metadata, dict):
        metadata = {'original_metadata_value': metadata}

    final_data = {}
    
    # Separate keys: Keep allowed ones at root, move others to metadata
    for key, value in data.items():
        if key in ALLOWED_KEYS:
            final_data[key] = value
        else:
            metadata[key] = value

    if metadata:
        final_data['metadata'] = metadata

    # Reconstruct the file with the new frontmatter
    # sort_keys=False helps maintain the original order for name/description
    new_yaml = yaml.dump(final_data, sort_keys=False, allow_unicode=True, width=1000).strip()
    new_content = f"---\n{new_yaml}\n---\n{body}"

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Successfully refactored: {file_path}")

def main():
    # Start walk from the current directory
    for root, _, files in os.walk('.'):
        for file in files:
            if file == 'SKILL.md':
                full_path = os.path.join(root, file)
                refactor_skill_file(full_path)

if __name__ == "__main__":
    main()
