import re

file_path = r"c:\Users\BSM-INFO\Downloads\dora\doraa_final\lib\widgets\ride_flow.dart"
with open(file_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if "Widget _buildPickupStep()" in line:
        start_idx = i
        break

if start_idx != -1:
    # Find the end of _buildEarningsStep
    in_earnings_step = False
    brace_count = 0
    for i in range(start_idx, len(lines)):
        line = lines[i]
        if "Widget _buildEarningsStep()" in line:
            in_earnings_step = True
        
        if in_earnings_step:
            brace_count += line.count('{')
            brace_count -= line.count('}')
            if brace_count == 0 and "}" in line:
                end_idx = i
                break

if start_idx != -1 and end_idx != -1:
    extracted = lines[start_idx:end_idx+1]
    
    # Write to new file
    new_file_path = r"c:\Users\BSM-INFO\Downloads\dora\doraa_final\lib\widgets\ride_flow_steps.dart"
    with open(new_file_path, "w", encoding="utf-8") as f:
        f.write("part of 'ride_flow.dart';\n\n")
        f.write("extension RideFlowStepsExtension on _RideFlowScreenState {\n")
        f.writelines(extracted)
        f.write("\n}\n")
    
    # Update old file
    new_lines = lines[:start_idx] + ["  // UI step methods have been moved to ride_flow_steps.dart via extension\n"] + lines[end_idx+1:]
    
    # Add part directive after imports
    for i, line in enumerate(new_lines):
        if line.strip() == "" or line.startswith("class "):
            # Find the last import
            last_import_idx = 0
            for j in range(i):
                if new_lines[j].startswith("import "):
                    last_import_idx = j
            new_lines.insert(last_import_idx + 1, "\npart 'ride_flow_steps.dart';\n")
            break
            
    with open(file_path, "w", encoding="utf-8") as f:
        f.writelines(new_lines)
    
    print(f"Success! Extracted {len(extracted)} lines to ride_flow_steps.dart")
else:
    print(f"Error: Could not find bounds. start={start_idx}, end={end_idx}")
