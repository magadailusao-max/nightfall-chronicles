#!/usr/bin/env python3
from pathlib import Path
from PIL import Image
import wave
root = Path(__file__).resolve().parents[1]
errors = []
for required in ['project.godot','main.tscn','scripts/main.gd','export_presets.cfg']:
    if not (root/required).is_file(): errors.append('missing '+required)
for i in range(1,25):
    for v in range(2):
        f = root/f'assets/rooms/room_{i:02d}_{v}.jpg'
        if not f.exists(): errors.append(f'missing {f}')
        else:
            with Image.open(f) as im:
                if im.size != (1152, 523): errors.append(f'bad size: {f.name}')
for i in range(12):
    path=root/f'assets/music/track_{i:02d}.wav'
    if not path.exists(): errors.append(f'missing {path}')
    else:
        with wave.open(str(path),'rb') as w:
            if (w.getnchannels(),w.getframerate(),w.getsampwidth()) != (2,44100,2): errors.append(f'bad audio: {path.name}')
for i in range(6):
    if not (root/f'assets/art/boss_{i}.png').exists(): errors.append(f'missing boss {i}')
for i in range(5):
    if not (root/f'assets/art/weapon_{i}.png').exists(): errors.append(f'missing weapon {i}')
print('Total source bytes:', sum(f.stat().st_size for f in root.rglob('*') if f.is_file()))
if errors:
    print('FAILED:','; '.join(errors)); raise SystemExit(1)
print('ASSET_CHECK_OK — 24 rooms, 48 variations, 12 WAVs, 6 bosses, 5 weapons')
