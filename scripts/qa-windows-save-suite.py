"""Export the actual save tests as an isolated Windows PE and run under Wine.

A release game ignores external --script; this harness registers the unchanged
SceneTree test as its main loop. It uses production src/data and its own user
folder, never the game's campaign folder. It is a test fixture, not gameplay.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import shutil

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--template', type=Path, required=True)
    parser.add_argument('--wine', type=Path, required=True)
    parser.add_argument('--prefix', type=Path, required=True)
    args = parser.parse_args()
    out = ROOT/'build/windows-save-probe'
    out.mkdir(parents=True, exist_ok=True)
    harness = Path(tempfile.mkdtemp(prefix='poliquetos-windows-save-'))
    if not (args.prefix/'drive_c').is_dir(): raise RuntimeError('Initialized QA prefix required')
    for name in ('src', 'data'):
        target = harness/name
        if target.exists() and target.resolve() != ROOT/name: raise RuntimeError('Unexpected harness directory')
        if not target.exists(): target.symlink_to(ROOT/name, target_is_directory=True)
    tests = harness/'native-tests'
    tests.mkdir(exist_ok=True)
    original = ROOT/'native-tests/campaign12_save_test.gd'
    (tests/'checks.gd').write_text('class_name PoliWindowsSaveChecks\n'+original.read_text())
    (harness/'project.godot').write_text('''config_version=5
[application]
config/name="Poliquetos save checks"
config/use_custom_user_dir=true
config/custom_user_dir_name="Poliquetos Save Probe 05A"
run/main_loop_type="PoliWindowsSaveChecks"
run/main_scene="res://blank.tscn"
[rendering]
renderer/rendering_method="gl_compatibility"
''')
    (harness/'blank.tscn').write_text('[gd_scene format=3]\n[node name="Blank" type="Node"]\n')
    (harness/'export_presets.cfg').write_text('''[preset.0]
name="Windows Probe"
platform="Windows Desktop"
runnable=true
advanced_options=false
export_filter="all_resources"
include_filter="*.json"
exclude_filter=""
export_path="checks.exe"
script_export_mode=2
[preset.0.options]
custom_template/release="%s"
binary_format/embed_pck=true
binary_format/architecture="x86_64"
codesign/enable=false
application/modify_resources=false
''' % args.template.resolve().as_posix())
    env = dict(os.environ)
    for key, name in [('XDG_DATA_HOME','user'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
        env[key] = str(out/name)
    commands = [
        ['godot','--headless','--editor','--path',str(harness),'--import','--quit'],
        ['godot','--headless','--path',str(harness),'--export-release','Windows Probe',str(out/'checks.exe')],
    ]
    for name, command in zip(('import','export'),commands):
        r = subprocess.run(command, env=env, capture_output=True, text=True, timeout=180)
        log = r.stdout+r.stderr
        (out/(name+'.log')).write_text(log)
        if r.returncode or 'ERROR:' in log: raise RuntimeError(name+' failed; inspect '+str(out))
    env.update(WINEPREFIX=str(args.prefix.resolve()), WINEDEBUG='-all',
               WINESERVER=str(args.wine.resolve().with_name('wineserver')))
    r = subprocess.run([str(args.wine),str(out/'checks.exe'),'--headless','--audio-driver','Dummy'],
                       env=env, capture_output=True, text=True, timeout=90)
    log = r.stdout+r.stderr
    (out/'windows-run.log').write_text(log)
    passed = r.returncode == 0 and 'CAMPAIGN12 SAVE PASS:' in log and '0 failures' in log and 'ERROR:' not in log
    manifest = {'passed':passed,'exit':r.returncode,'host':'Windows PE under Wine/Linux, not physical Windows',
                'scope':'Isolated save tests; not a gameplay video or installer test',
                'user_folder':'Poliquetos Save Probe 05A','test_sha256':hashlib.sha256(original.read_bytes()).hexdigest(),
                'save_sha256':hashlib.sha256((ROOT/'src/save/saves.gd').read_bytes()).hexdigest(),
                'exe_sha256':hashlib.sha256((out/'checks.exe').read_bytes()).hexdigest()}
    (out/'report.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(log)
    print(json.dumps(manifest,indent=2))
    if passed: shutil.rmtree(harness)
    return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
