"""Run native checks and reject Godot script errors even when Godot exits with0."""
import argparse,json,os,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render',action='store_true',help='Also render screenshots/benchmark using DISPLAY')
    args=parser.parse_args()
    out=ROOT/'build/test-reports';out.mkdir(parents=True,exist_ok=True)
    env=dict(os.environ)
    for key,name in [('XDG_DATA_HOME','user'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:env[key]=str(out/name)
    records=[]
    def run(name,command,timeout=90,expected=None):
        result=subprocess.run(command,cwd=ROOT,env=env,capture_output=True,text=True,timeout=timeout)
        text=result.stdout+result.stderr
        (out/f'{name}.log').write_text(text)
        passed=result.returncode==0 and 'SCRIPT ERROR:' not in text and 'ERROR:' not in text and 'Assertion failed' not in text
        if expected:passed=passed and expected.lower() in text.lower()
        records.append({'name':name,'passed':passed,'exit':result.returncode})
        print(('PASS ' if passed else 'FAIL ')+name,flush=True)
        if not passed:
            print(text[-6000:]);raise RuntimeError(name+' failed')
    # Refresh changed PNG imports before comparing artist files with loaded pixels.
    # Without an editor watching files, an old .godot cache can show old artwork.
    run('import',['godot','--headless','--editor','--path',str(ROOT),'--import','--quit'],timeout=180)
    run('python-contracts',[sys.executable,'-m','unittest','discover','-s','native-tests','-p','test_*.py'])
    run('schemas',[sys.executable,'scripts/validate-v2-data.py','--self-test'])
    for path in sorted((ROOT/'native-tests').glob('*test.gd')):
        if path.name in ('performance_test.gd','visual_test.gd'):continue
        run(path.stem,['godot','--headless','--path',str(ROOT),'--script',str(path)],expected='0 failures' if path.stem=='shop_save_test' else 'pass')
    run('normal-start',['godot','--headless','--path',str(ROOT),'--','--verify-export'],expected='EXPORT_VERIFY_PASS')
    run('pruebas-start',['godot','--headless','--path',str(ROOT),'--','--pruebas','--verify-export'],expected='EXPORT_VERIFY_PASS')
    for edition in ('normal','pruebas'):
        command=['godot','--headless','--path',str(ROOT),'--script','native-tests/export_stage_probe.gd','--']
        if edition=='pruebas':command.append('--pruebas')
        run(edition+'-stage-runtime',command,expected='EXPORT_STAGE_PASS')
    for edition in ('normal','pruebas'):
        command=['godot','--headless','--path',str(ROOT),'--script','native-tests/art_w01_quit.gd','--']
        if edition=='pruebas':command.append('--pruebas')
        run(edition+'-quit',command,timeout=20,expected='W01 QUIT PASS')
    if args.render:
        if not env.get('DISPLAY'):raise RuntimeError('--render requires a real/dummyX display')
        for name in ['visual','performance']:
            run(name,['godot','--path',str(ROOT),'--audio-driver','Dummy','--rendering-method','gl_compatibility','--script',f'native-tests/{name}_test.gd'],expected='VISUAL PASS' if name=='visual' else 'PERFORMANCE')
    (out/'results.json').write_text(json.dumps(records,indent=2)+'\n')
    print(f'{len(records)} native checks passed. Logs: {out}')
if __name__=='__main__':main()
