#!/usr/bin/env python3
"""Configure Godot 4 Android editor preferences in CI after first --import.

The settings are editor/user-scoped rather than project-scoped. This script
keeps SDK paths out of source control and only edits the current runner.
"""
import os
from pathlib import Path

sdk = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
java = os.environ.get('JAVA_HOME')
if not sdk or not java:
    raise SystemExit('ANDROID_HOME and JAVA_HOME must both be configured')
if not (Path(sdk)/'platform-tools'/'adb').is_file():
    raise SystemExit(f'Android platform tools were not found under {sdk}')
if not (Path(java)/'bin'/'java').is_file():
    raise SystemExit(f'Java was not found under {java}')
config=Path.home()/'.config/godot/editor_settings-4.tres'
config.parent.mkdir(parents=True, exist_ok=True)
content=config.read_text() if config.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
if '[resource]' not in content:
    raise SystemExit('Unrecognized Godot editor settings format')
for field, value in {'export/android/android_sdk_path':sdk,'export/android/java_sdk_path':java}.items():
    lines=[ln for ln in content.splitlines() if not ln.startswith(field+' = ')]
    content='\n'.join(lines).rstrip()+'\n'
    content=content.replace('[resource]\n','[resource]\n'+f'{field} = "{value}"\n',1)
config.write_text(content)
print('Godot Android export preferences configured for this runner.')
