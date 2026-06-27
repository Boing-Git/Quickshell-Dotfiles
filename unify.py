import os
import re

replacements = [
    # Margins
    (r'anchors\.margins:\s*20', r'anchors.margins: Vars.spacingLarge'),
    (r'anchors\.margins:\s*24', r'anchors.margins: Vars.spacingLarge'),
    (r'anchors\.margins:\s*16', r'anchors.margins: Vars.spacingMedium'),
    (r'anchors\.margins:\s*12', r'anchors.margins: Vars.spacingMedium'),
    (r'anchors\.margins:\s*8', r'anchors.margins: Vars.spacingSmall'),
    (r'anchors\.margins:\s*10', r'anchors.margins: Vars.spacingSmall'),
    
    (r'margins\.right:\s*20', r'margins.right: Vars.spacingLarge'),
    (r'margins\.left:\s*20', r'margins.left: Vars.spacingLarge'),
    
    (r'anchors\.leftMargin:\s*8\b', r'anchors.leftMargin: Vars.spacingSmall'),
    (r'anchors\.rightMargin:\s*10\b', r'anchors.rightMargin: Vars.spacingSmall'),
    (r'anchors\.rightMargin:\s*12\b', r'anchors.rightMargin: Vars.spacingMedium'),
    (r'anchors\.leftMargin:\s*6\b', r'anchors.leftMargin: Vars.spacingSmall'),
    
    (r'anchors\.leftMargin:\s*16', r'anchors.leftMargin: Vars.spacingMedium'),
    (r'anchors\.rightMargin:\s*16', r'anchors.rightMargin: Vars.spacingMedium'),
    (r'anchors\.leftMargin:\s*18', r'anchors.leftMargin: Vars.spacingMedium'),
    (r'anchors\.topMargin:\s*12', r'anchors.topMargin: Vars.spacingMedium'),
    (r'anchors\.bottomMargin:\s*12', r'anchors.bottomMargin: Vars.spacingMedium'),
    (r'anchors\.topMargin:\s*10', r'anchors.topMargin: Vars.spacingSmall'),
    
    # Layout margins
    (r'Layout\.topMargin:\s*10\b', r'Layout.topMargin: Vars.spacingSmall'),
    (r'Layout\.topMargin:\s*20\b', r'Layout.topMargin: Vars.spacingLarge'),
    (r'Layout\.bottomMargin:\s*20\b', r'Layout.bottomMargin: Vars.spacingLarge'),
    (r'Layout\.topMargin:\s*4\b', r'Layout.topMargin: (Vars.spacingSmall / 2)'),
    
    # Spacing
    (r'spacing:\s*16\b', r'spacing: Vars.spacingMedium'),
    (r'spacing:\s*14\b', r'spacing: Vars.spacingMedium'),
    (r'spacing:\s*12\b', r'spacing: Vars.spacingMedium'),
    (r'spacing:\s*10\b', r'spacing: Vars.spacingSmall'),
    (r'spacing:\s*8\b', r'spacing: Vars.spacingSmall'),
    
    # Radii
    (r'radius:\s*16\b', r'radius: Vars.radiusMedium'),
    (r'radius:\s*8\b', r'radius: Vars.radiusSmall'),
    (r'radius:\s*24\b', r'radius: Vars.radiusLarge'),
    (r'radius:\s*12\b', r'radius: Math.floor(Vars.radiusMedium * 0.75)'),
    (r'radius:\s*4\b', r'radius: Math.floor(Vars.radiusSmall / 2)'),
    (r'radius:\s*3\b', r'radius: Math.floor(Vars.radiusSmall / 2.5)'),
    (r'radius:\s*2\b', r'radius: Math.floor(Vars.radiusSmall / 4)'),
    (r'radius:\s*1\.5\b', r'radius: Math.floor(Vars.radiusSmall / 5)'),
]

dir_path = '/home/boing/.config/quickshell'
for root_dir, _, files in os.walk(dir_path):
    for file in files:
        if file.endswith('.qml'):
            path = os.path.join(root_dir, file)
            with open(path, 'r') as f:
                content = f.read()
            original = content
            for p, r in replacements:
                content = re.sub(p, r, content)
            if original != content:
                with open(path, 'w') as f:
                    f.write(content)
                print(f"Updated {file}")
