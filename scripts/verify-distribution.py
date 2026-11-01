"""Verify installer CRC, exact exported payload, PE/PCK structure and packed startup.
Godot's Linux runtime reads each Windows EXE's embedded pack for the startup probe;
this is not a claim of running the Windows operating system or its GPU drivers.
"""
import argparse,hashlib,json,os,struct,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--sevenzip',required=True)
    args=p.parse_args()
    (ROOT/'build/test-reports').mkdir(parents=True,exist_ok=True)
    records=[]
    for edition in ('Normal','Pruebas'):
        installer=ROOT/f'entregas/Poliquetos-{edition}-Instalar.exe'
        with tempfile.TemporaryDirectory(prefix='poliquetos-distribution-') as tmp:
            folder=Path(tmp)
            for command in [[args.sevenzip,'t',str(installer)],[args.sevenzip,'x','-y',f'-o{folder}',str(installer)]]:
                r=subprocess.run(command,capture_output=True,text=True,timeout=90)
                if r.returncode:raise RuntimeError(r.stdout+r.stderr)
            exe=folder/f'Poliquetos-{edition}.exe'
            data=exe.read_bytes()
            original=ROOT/f'build/Poliquetos-{edition}.exe'
            if hashlib.sha256(data).digest()!=hashlib.sha256(original.read_bytes()).digest():raise RuntimeError('Installer payload mismatch')
            pe=struct.unpack_from('<I',data,0x3c)[0]
            if data[:2]!=b'MZ' or data[pe:pe+4]!=b'PE\0\0' or struct.unpack_from('<H',data,pe+4)[0]!=0x8664:raise RuntimeError('Not Windowsx64 PE')
            if data[-4:]!=b'GDPC':raise RuntimeError('Missing embedded Godot PCK')
            for name in ['LICENSE-Godot.txt','COPYRIGHT-Godot.txt']:
                if not (folder/name).is_file():raise RuntimeError('Missing '+name)
            env=dict(os.environ,XDG_DATA_HOME=str(folder/'data'),XDG_CONFIG_HOME=str(folder/'config'),XDG_CACHE_HOME=str(folder/'cache'))
            r=subprocess.run(['godot','--headless','--main-pack',str(exe),'--','--verify-export'],cwd=folder,env=env,capture_output=True,text=True,timeout=40)
            log=r.stdout+r.stderr
            expected='pruebas' if edition=='Pruebas' else 'normal'
            if r.returncode or 'ERROR:' in log or 'EXPORT_VERIFY_PASS edition='+expected not in log:raise RuntimeError(log)
            (ROOT/'build/test-reports'/('export-'+edition.lower()+'-start.log')).write_text(log)
            r=subprocess.run(['godot','--headless','--main-pack',str(exe),'--script',str(ROOT/'native-tests/export_stage_probe.gd')],cwd=folder,env=env,capture_output=True,text=True,timeout=40)
            stage_log=r.stdout+r.stderr
            (ROOT/'build/test-reports'/('export-'+edition.lower()+'-stage.log')).write_text(stage_log)
            if r.returncode or 'ERROR:' in stage_log or 'EXPORT_STAGE_PASS' not in stage_log:raise RuntimeError(stage_log)
            report_line=next(line for line in stage_log.splitlines() if line.startswith('EXPORT_STAGE_REPORT '))
            stage_report=json.loads(report_line.removeprefix('EXPORT_STAGE_REPORT '))
            if stage_report['edition']!=expected:raise RuntimeError('Stage probe edition mismatch')
            records.append({'edition':edition,'installer_bytes':installer.stat().st_size,'installer_sha256':hashlib.sha256(installer.read_bytes()).hexdigest(),'payload_sha256':hashlib.sha256(data).hexdigest(),'windows_pe_x64':True,'embedded_pck':True,'installer_crc_and_payload':True,'packed_runtime_probe':expected,'stage_probe':stage_report,'probe_host':'Godot Linux 4.6.3, not native Windows'})
            print('DISTRIBUTION PASS '+edition,flush=True)
    linux=ROOT/'build/poliquetos-linux.x86_64'
    if linux.exists():
        with tempfile.TemporaryDirectory(prefix='poliquetos-linux-') as tmp:
            env=dict(os.environ,XDG_DATA_HOME=tmp+'/data',XDG_CONFIG_HOME=tmp+'/config',XDG_CACHE_HOME=tmp+'/cache')
            r=subprocess.run([str(linux),'--headless','--','--verify-export'],env=env,capture_output=True,text=True,timeout=40)
            log=r.stdout+r.stderr
            if r.returncode or 'ERROR:' in log or 'EXPORT_VERIFY_PASS edition=normal' not in log:raise RuntimeError(log)
            print('STANDALONE LINUX PASS (validation export)',flush=True)
    (ROOT/'docs/verificacion/distribucion.json').write_text(json.dumps(records,indent=2)+'\n')
if __name__=='__main__':main()
