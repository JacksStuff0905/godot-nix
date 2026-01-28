import sys
import os

user_path = sys.argv[1]
nix_path = sys.argv[2]

# 1. Read the Nix Enforced Settings into a dictionary
nix_settings = {}
if os.path.exists(nix_path):
    with open(nix_path, 'r') as f:
        for line in f:
            if "=" in line:
                key, value = line.split("=", 1)
                nix_settings[key.strip()] = value.strip()

# 2. Read User Settings and update lines if they match Nix keys
output_lines = []
found_keys = set()

if os.path.exists(user_path):
    with open(user_path, 'r') as f:
        for line in f:
            line_stripped = line.strip()
            # Check if this line starts with a key we want to enforce
            key_match = None
            for key in nix_settings:
                if line_stripped.startswith(key + " =") or line_stripped.startswith(key + "="):
                    key_match = key
                    break

            if key_match:
                # Replace with Nix value
                output_lines.append(f"{key_match} = {nix_settings[key_match]}\n")
                found_keys.add(key_match)
            else:
                # Keep user value
                output_lines.append(line)
else:
    # If file doesn't exist, create header
    output_lines.append('[gd_resource type="EditorSettings" format=3]\n\n')
    output_lines.append('[resource]\n')

# 3. Append Nix settings that weren't in the user file yet
for key, value in nix_settings.items():
    if key not in found_keys:
        output_lines.append(f"{key} = {value}\n")

# 4. Write back to user file
with open(user_path, 'w') as f:
    f.writelines(output_lines)
