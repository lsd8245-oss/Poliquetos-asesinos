"""Drive the real Windows EXE under Wine via X11 keyboard, recording its window.

Linux/Wine evidence is NOT certification on a real Windows installation.
No PCK patching, enemy injection, timer manipulation, upgrades or invulnerability.
Requires a dedicated X display, libX11/libXtst, ffmpeg and the optional game trace.
"""
import argparse
import ctypes as C
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time
from PIL import Image


class XImage(C.Structure):
    _fields_=[('width',C.c_int),('height',C.c_int),('xoffset',C.c_int),('format',C.c_int),('data',C.c_void_p),('byte_order',C.c_int),('bitmap_unit',C.c_int),('bitmap_bit_order',C.c_int),('bitmap_pad',C.c_int),('depth',C.c_int),('bytes_per_line',C.c_int),('bits_per_pixel',C.c_int),('red_mask',C.c_ulong),('green_mask',C.c_ulong),('blue_mask',C.c_ulong)]


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--exe',type=Path,required=True)
    p.add_argument('--wine',required=True)
    p.add_argument('--prefix',required=True)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--display',default=':91')
    p.add_argument('--scale',type=int,choices=(1,2,3),default=2)
    p.add_argument('--seconds',type=int,choices=(20,40),default=20,help='Effective game time, not capture duration')
    p.add_argument('--legacy',action='store_true',help='Record old EXE with no trace; do not claim its timer advanced')
    a=p.parse_args()
    out=a.output.resolve();out.mkdir(parents=True,exist_ok=True)
    width,height=640*a.scale,360*a.scale
    edition='pruebas' if 'pruebas' in a.exe.name.lower() else 'normal'
    # Configure scale and disable autofire in the dedicated QA prefix.
    # XResizeWindow on Wine's parent alone clips the GL child, giving false QA.
    data_dirs=list(Path(a.prefix).glob('drive_c/users/*/AppData/Roaming/Poliquetos Asesinos'))
    assert len(data_dirs)==1,'Initialize this dedicated QA prefix by opening the game once'
    pref=data_dirs[0]/edition/'options.json';pref.parent.mkdir(parents=True,exist_ok=True)
    options=json.loads(pref.read_text()) if pref.exists() else {}
    options['screen']=f'window{a.scale}'
    options['autofire']=False
    options['show_hitbox']=False
    pref.write_text(json.dumps(options))
    env=dict(os.environ,DISPLAY=a.display,WINEPREFIX=a.prefix,WINEDEBUG='-all',WINEDLLOVERRIDES='zlib1=n',WINESERVER=str(Path(a.wine).with_name('wineserver')),XDG_CACHE_HOME=str(out/'cache'))
    x=C.CDLL('libX11.so.6');xt=C.CDLL('libXtst.so.6')
    x.XOpenDisplay.argtypes=[C.c_char_p];x.XOpenDisplay.restype=C.c_void_p
    display=x.XOpenDisplay(a.display.encode());assert display,'X display unavailable'
    x.XDefaultRootWindow.argtypes=[C.c_void_p];x.XDefaultRootWindow.restype=C.c_ulong
    root=x.XDefaultRootWindow(display)
    x.XStringToKeysym.argtypes=[C.c_char_p];x.XStringToKeysym.restype=C.c_ulong
    x.XKeysymToKeycode.argtypes=[C.c_void_p,C.c_ulong];x.XKeysymToKeycode.restype=C.c_uint
    xt.XTestFakeKeyEvent.argtypes=[C.c_void_p,C.c_uint,C.c_int,C.c_ulong]
    x.XFlush.argtypes=[C.c_void_p]
    x.XSetInputFocus.argtypes=[C.c_void_p,C.c_ulong,C.c_int,C.c_ulong]
    x.XRaiseWindow.argtypes=[C.c_void_p,C.c_ulong]
    x.XMoveWindow.argtypes=[C.c_void_p,C.c_ulong,C.c_int,C.c_int]
    x.XGetImage.argtypes=[C.c_void_p,C.c_ulong,C.c_int,C.c_int,C.c_uint,C.c_uint,C.c_ulong,C.c_int];x.XGetImage.restype=C.POINTER(XImage)
    x.XDestroyImage.argtypes=[C.POINTER(XImage)]
    held=set()
    def key(name,pressed):
        if pressed:
            x.XRaiseWindow(display,window);x.XSetInputFocus(display,window,2,0)
        code=x.XKeysymToKeycode(display,x.XStringToKeysym(name.encode()))
        xt.XTestFakeKeyEvent(display,code,int(pressed),0);x.XFlush(display)
        if pressed:held.add(name)
        else:held.discard(name)
    def tap(name):
        key(name,True);time.sleep(.08);key(name,False);time.sleep(.2)
    def shot(name):
        image=x.XGetImage(display,root,0,0,width,height,C.c_ulong(-1).value,2)
        assert image and image.contents.bits_per_pixel==32
        raw=C.string_at(image.contents.data,image.contents.bytes_per_line*height)
        im=Image.frombytes('RGB',(width,height),raw,'raw','BGRX',image.contents.bytes_per_line,1)
        im.save(out/(name+'.png'));x.XDestroyImage(image)
    logfile=out/'game.log'
    winlog='Z:'+str(logfile).replace('\\','/')
    stdout=open(out/'wine.log','w')
    command=[a.wine,str(a.exe.resolve()),'--borderless','--position','0,0','--resolution','1280x720','--rendering-method','gl_compatibility','--rendering-driver','opengl3','--audio-driver','Dummy','--log-file',winlog,'--','--runtime-trace']
    app=subprocess.Popen(command,cwd=a.exe.resolve().parent,env=env,stdout=stdout,stderr=subprocess.STDOUT)
    recorder=None
    try:
        window=None
        deadline=time.monotonic()+25
        while time.monotonic()<deadline:
            tree=subprocess.check_output(['xwininfo','-root','-tree'],env=env,text=True)
            match=re.search(r'(0x[0-9a-f]+) "Poliquetos Asesinos"',tree)
            if match:window=int(match.group(1),16);break
            if app.poll() is not None:raise RuntimeError('Windows EXE exited before opening a window')
            time.sleep(.2)
        assert window,'Windows game window not found'
        x.XRaiseWindow(display,window);x.XMoveWindow(display,window,0,0);x.XSetInputFocus(display,window,2,0);x.XFlush(display)
        time.sleep(3)
        tap('Return');time.sleep(.3)
        x.XMoveWindow(display,window,0,0);x.XFlush(display);time.sleep(.3)
        tree=subprocess.check_output(['xwininfo','-root','-tree'],env=env,text=True)
        assert re.search(r'"Poliquetos Asesinos"[^\n]*\s'+f'{width}x{height}'+r'\+0\+0',tree),tree
        recorder=subprocess.Popen(['ffmpeg','-hide_banner','-loglevel','error','-f','x11grab','-framerate','20','-video_size',f'{width}x{height}','-i',a.display+'+0,0','-c:v','libx264','-threads','1','-preset','ultrafast','-crf','28','-pix_fmt','yuv420p','-y',str(out/'gameplay.mp4')],stdin=subprocess.PIPE,stdout=subprocess.DEVNULL,stderr=open(out/'ffmpeg.log','w'),env=env)
        shot('menu')
        tap('Return');tap('Down');tap('Return');tap('Return')
        # A fresh QA prefix has empty slots. A repeated run confirms overwrite.
        time.sleep(.5)
        text=(out/'wine.log').read_text(errors='replace')
        if 'RUNTIME_STAGE_TRACE' not in text:
            tap('Right');tap('Return')
        start=time.monotonic();samples={};actions=set()
        expected={0,5,12,20} if a.seconds==20 else {0,5,12,15,20,30,40}
        while time.monotonic()-start<110:
            elapsed=time.monotonic()-start
            # Normal physical keyboard input only; first demonstrate lateral move.
            for mark,name,press in [(2.1,'d',True),(2.5,'d',False),(2.6,'a',True),(3.0,'a',False),(14.5,'w',True),(16.5,'w',False),(15.5,'z',True)]+([(29.0,'x',True),(29.2,'x',False)] if a.seconds==40 else []):
                if elapsed>=mark and mark not in actions:key(name,press);actions.add(mark)
            text=(out/'wine.log').read_text(errors='replace')
            for line in text.splitlines():
                if line.startswith('RUNTIME_STAGE_TRACE '):
                    item=json.loads(line.removeprefix('RUNTIME_STAGE_TRACE '));target=int(item['target_elapsed'])
                    if target in expected and target not in samples:
                        samples[target]=item;time.sleep(.12);shot(f't{target:02d}')
            if a.legacy:
                for target in (0,5,12,20):
                    if elapsed>=target+2 and target not in samples:
                        shot(f't{target:02d}');samples[target]={'wall_elapsed':elapsed,'trace_unavailable_in_old_binary':True}
            if a.seconds in samples:time.sleep(1);break
            if app.poll() is not None:raise RuntimeError('Windows game exited during play')
            time.sleep(.05)
        for name in list(held):key(name,False)
        # Exit through the real pause -> title -> Salir -> confirmation flow.
        tap('Escape')
        for _ in range(3):tap('Down')
        tap('Return');tap('Right');tap('Return')
        for _ in range(4):tap('Down')
        tap('Return');tap('Right');tap('Return')
        app.wait(timeout=12)
        if not a.legacy:
            assert set(samples)==expected,samples
            last=samples[a.seconds]
            assert last['world_time']>=a.seconds and last['scroll']>=60*a.seconds and last['regular_spawned']>=4 and last['regular_kills']>=1,last
            assert all(s[n] for s in samples.values() for n in ('stage_system','weapon_system','boss_system'))
            assert any(s['enemy_bullets']>0 for s in samples.values()),samples
            assert app.returncode==0,app.returncode
            assert 'ERROR:' not in (out/'wine.log').read_text(errors='replace')
        report={'executable':str(a.exe.resolve()),'sha256':hashlib.sha256(a.exe.read_bytes()).hexdigest(),'resolution':[width,height],'host':'Linux, Wine10 compatibility layer; NOT real Windows','capture':'Real Windows EXE window, X11 keyboard and screen recording','wall_seconds':time.monotonic()-start,'samples':samples,'passed':not a.legacy,'legacy_observation':a.legacy,'exit_code':app.returncode}
        (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
        print(json.dumps(report,indent=2))
    finally:
        for name in list(held):key(name,False)
        if recorder:
            recorder.communicate(b'q',timeout=15)
        if app.poll() is None:app.terminate();app.wait(timeout=10)
        stdout.close()


if __name__=='__main__':main()
