"""Record 04A from a Windows PE under Wine using real X11 keyboard input.

This is Linux/Wine evidence, not certification on a physical Windows machine.
Only the dedicated prefix's preferences are prepared; campaigns are created and
overwritten through the real UI. No stage, player, enemy or clock is injected.
"""
import argparse
import ctypes as C
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import re
import subprocess
import time

from PIL import Image


HELPERS = importlib.util.spec_from_file_location(
    "exported_windows_qa", Path(__file__).with_name("qa-exported-windows.py"))
_helpers = importlib.util.module_from_spec(HELPERS)
HELPERS.loader.exec_module(_helpers)
XImage = _helpers.XImage
TARGETS = {0, 5, 12, 15, 20, 30, 40}
TRACE_TYPES = ("DISPLAY_TRACE", "SONAR_TRACE", "SONAR_STATE", "RUNTIME_STAGE_TRACE")


class Session:
    def __init__(self, args, report):
        self.args, self.report = args, report
        self.out = args.output.resolve()
        self.started = time.monotonic()
        self.window = None
        self.held = set()
        self.events = {kind: [] for kind in TRACE_TYPES}
        self.samples = {}
        self.trace_offset = 0
        self.trace_pending = ""
        self.app = self.recorder = None
        self.streams = []
        self.env = dict(os.environ, DISPLAY=args.display, WINEPREFIX=str(args.prefix.resolve()),
                        WINEDEBUG="-all", WINEDLLOVERRIDES="zlib1=n",
                        WINESERVER=str(Path(args.wine).with_name("wineserver")),
                        XDG_CACHE_HOME=str(args.cache.resolve()))
        self.x = C.CDLL("libX11.so.6")
        self.xt = C.CDLL("libXtst.so.6")
        definitions = {
            "XOpenDisplay": ([C.c_char_p], C.c_void_p),
            "XDefaultRootWindow": ([C.c_void_p], C.c_ulong),
            "XStringToKeysym": ([C.c_char_p], C.c_ulong),
            "XKeysymToKeycode": ([C.c_void_p, C.c_ulong], C.c_uint),
            "XFlush": ([C.c_void_p], C.c_int),
            "XSetInputFocus": ([C.c_void_p, C.c_ulong, C.c_int, C.c_ulong], C.c_int),
            "XRaiseWindow": ([C.c_void_p, C.c_ulong], C.c_int),
            "XWarpPointer": ([C.c_void_p, C.c_ulong, C.c_ulong, C.c_int, C.c_int,
                              C.c_uint, C.c_uint, C.c_int, C.c_int], C.c_int),
            "XGetImage": ([C.c_void_p, C.c_ulong, C.c_int, C.c_int, C.c_uint,
                           C.c_uint, C.c_ulong, C.c_int], C.POINTER(XImage)),
            "XDestroyImage": ([C.POINTER(XImage)], C.c_int),
            "XCloseDisplay": ([C.c_void_p], C.c_int),
        }
        for name, (argtypes, restype) in definitions.items():
            getattr(self.x, name).argtypes = argtypes
            getattr(self.x, name).restype = restype
        self.xt.XTestFakeKeyEvent.argtypes = [C.c_void_p, C.c_uint, C.c_int, C.c_ulong]
        self.display = self.x.XOpenDisplay(args.display.encode())
        if not self.display:
            raise RuntimeError("X display unavailable")
        self.root = self.x.XDefaultRootWindow(self.display)
        xrandr = subprocess.check_output(["xrandr", "--current"], env=self.env, text=True)
        (self.out / "xrandr.txt").write_text(xrandr)
        size = re.search(r"current\s+(\d+)\s+x\s+(\d+)", xrandr)
        if not size:
            raise RuntimeError("Cannot read actual root desktop dimensions from XRandR")
        self.width, self.height = map(int, size.groups())
        report["desktop_size"] = [self.width, self.height]

    def guard(self):
        if time.monotonic() - self.started > 180:
            raise RuntimeError("180 second session limit exceeded")
        if self.app is not None and self.app.poll() is not None:
            raise RuntimeError(f"Windows PE exited unexpectedly: {self.app.returncode}")

    def pump(self):
        self.guard()
        log = self.out / "wine.log"
        if not log.exists():
            return
        with log.open(errors="replace") as stream:
            stream.seek(self.trace_offset)
            data = self.trace_pending + stream.read()
            self.trace_offset = stream.tell()
        lines = data.split("\n")
        self.trace_pending = lines.pop()
        for line in lines:
            for kind in TRACE_TYPES:
                if not line.startswith(kind + " "):
                    continue
                item = json.loads(line[len(kind) + 1:])
                self.events[kind].append({"wall_seconds": time.monotonic() - self.started,
                                          "data": item})
                if kind == "RUNTIME_STAGE_TRACE":
                    target = int(item["target_elapsed"])
                    if target in TARGETS and target not in self.samples:
                        self.samples[target] = item
                        self.shot(f"t{target:02d}")

    def sleep(self, seconds):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            self.pump()
            time.sleep(min(.05, max(0, deadline - time.monotonic())))
        self.pump()

    def wait(self, condition, description, timeout=25):
        deadline = min(self.started + 180, time.monotonic() + timeout)
        while time.monotonic() < deadline:
            self.pump()
            value = condition()
            if value:
                return value
            time.sleep(.05)
        raise RuntimeError("Timed out waiting for " + description)

    def focus(self):
        tree = subprocess.check_output(["xwininfo", "-root", "-tree"], env=self.env, text=True)
        found = re.search(r'(0x[0-9a-fA-F]+) "Poliquetos Asesinos"', tree)
        if not found:
            raise RuntimeError("Windows game window not found")
        self.window = int(found.group(1), 16)
        self.x.XRaiseWindow(self.display, self.window)
        self.x.XSetInputFocus(self.display, self.window, 2, 0)
        # A stationary cursor over a menu row can change selection after resize.
        self.x.XWarpPointer(self.display, 0, self.root, 0, 0, 0, 0,
                            self.width - 2, self.height - 2)
        self.x.XFlush(self.display)

    def key(self, name, pressed):
        if pressed:
            self.x.XRaiseWindow(self.display, self.window)
            self.x.XSetInputFocus(self.display, self.window, 2, 0)
        code = self.x.XKeysymToKeycode(self.display, self.x.XStringToKeysym(name.encode()))
        if not code:
            raise RuntimeError("Unknown keyboard key: " + name)
        self.xt.XTestFakeKeyEvent(self.display, code, int(pressed), 0)
        self.x.XFlush(self.display)
        (self.held.add if pressed else self.held.discard)(name)

    def tap(self, name, count=1):
        for _ in range(count):
            self.key(name, True)
            self.sleep(.08)
            self.key(name, False)
            self.sleep(.2)

    def shot(self, name):
        image = self.x.XGetImage(self.display, self.root, 0, 0, self.width, self.height,
                                C.c_ulong(-1).value, 2)
        if not image:
            raise RuntimeError("XGetImage failed")
        try:
            info = image.contents
            if info.bits_per_pixel != 32 or (info.red_mask, info.green_mask, info.blue_mask) != (0xff0000, 0xff00, 0xff):
                raise RuntimeError("Unsupported desktop pixel format")
            raw = C.string_at(info.data, info.bytes_per_line * self.height)
            Image.frombytes("RGB", (self.width, self.height), raw, "raw", "BGRX",
                            info.bytes_per_line, 1).save(self.out / (name + ".png"))
            self.report.setdefault("screenshots", {})[name] = [self.width, self.height]
        finally:
            self.x.XDestroyImage(image)

    def display_mode(self, key, mode):
        offset = len(self.events["DISPLAY_TRACE"])
        self.tap(key)
        metric = self.wait(lambda: next((entry["data"] for entry in
                            self.events["DISPLAY_TRACE"][offset:]
                            if entry["data"].get("requested_mode") == mode), None), mode)
        self.sleep(1)
        self.focus()
        return metric

    def prepare(self):
        prefix = self.args.prefix.resolve()
        if prefix == Path.home() / ".wine" or prefix == Path("/"):
            raise RuntimeError("Use a dedicated QA Wine prefix, never a personal prefix")
        if not (prefix / "drive_c").is_dir():
            raise RuntimeError("Initialize the dedicated QA Wine prefix first")
        dirs = list(prefix.glob("drive_c/users/*/AppData/Roaming/Poliquetos Asesinos"))
        if len(dirs) != 1:
            raise RuntimeError("Expected one game's data directory in the dedicated prefix")
        edition = "pruebas" if "pruebas" in self.args.exe.name.lower() else "normal"
        pref = dirs[0] / edition / "options.json"
        if not pref.resolve().is_relative_to(prefix):
            raise RuntimeError("Preferences resolve outside the dedicated prefix")
        original = pref.read_text() if pref.exists() else None
        (self.out / "preferences-before.json").write_text(json.dumps({"path": str(pref), "content": original}, indent=2))
        options = json.loads(original) if original is not None else {}
        options.update(screen="window2", autofire=False, show_hitbox=False)
        bindings = options.setdefault("bindings", {})
        bindings.pop("key:sonar", None)
        bindings.pop("joy:sonar", None)
        pref.parent.mkdir(parents=True, exist_ok=True)
        pref.write_text(json.dumps(options, indent=2) + "\n")
        self.pref = pref
        self.report["preferences"] = str(pref)
        self.args.cache.mkdir(parents=True, exist_ok=True)

    def launch(self):
        stdout = (self.out / "wine.log").open("w")
        errors = (self.out / "ffmpeg.log").open("w")
        self.streams.extend([stdout, errors])
        exe = self.args.exe.resolve()
        command = [self.args.wine, str(exe), "--rendering-method", "gl_compatibility",
                   "--rendering-driver", "opengl3", "--audio-driver", "Dummy",
                   "--log-file", "Z:" + str(self.out / "game.log"), "--", "--runtime-trace"]
        self.report["command"] = command
        self.app = subprocess.Popen(command, cwd=exe.parent, env=self.env,
                                    stdout=stdout, stderr=subprocess.STDOUT)
        def opened():
            try:
                self.focus()
                return True
            except RuntimeError:
                return False
        self.wait(opened, "Windows game window")
        self.recorder = subprocess.Popen(
            ["ffmpeg", "-hide_banner", "-loglevel", "error", "-f", "x11grab",
             "-framerate", "20", "-video_size", f"{self.width}x{self.height}",
             "-i", self.args.display + "+0,0", "-c:v", "libx264", "-threads", "1",
             "-preset", "ultrafast", "-crf", "22", "-pix_fmt", "yuv420p",
             "-y", str(self.out / "gameplay.mp4")], env=self.env, stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL, stderr=errors)
        self.wait(lambda: self.events["DISPLAY_TRACE"], "application ready / initial preferences", 35)
        self.sleep(.4)
        self.tap("Return")
        self.shot("title")

    def run(self):
        self.prepare()
        self.launch()
        self.tap("Down", 2)
        self.tap("Return")
        self.tap("Down", 3)
        adjusted = self.display_mode("Right", "window3")
        self.shot("window3-options")
        fill = self.display_mode("Right", "fullscreen_fill")
        self.shot("fill-options")
        pixel = self.display_mode("Right", "fullscreen_pixel")
        self.shot("pixel-options")
        if self.args.display_only:
            self.display_mode("Right", "window1")
            window = self.display_mode("Right", "window2")
            self.shot("window2-options")
            self.tap("Escape")
            self.tap("Down", 4)
            self.tap("Return")
            self.tap("Right")
            self.key("Return", True)
            time.sleep(.08)
            self.key("Return", False)
            self.app.wait(timeout=12)
            self.report["display_checks"] = {"window3": adjusted, "fill": fill, "pixel": pixel, "window2": window}
            for metric in (fill, pixel):
                if metric["window_mode"] != 4 or metric["window_size"] != [self.width, self.height] or metric["clipped"]:
                    raise RuntimeError("Actual fullscreen matrix failed")
            for metric in (fill, pixel, window):
                if metric["viewport_size"] != [640, 360] or any(abs(a-b)>.005 for a,b in zip(metric["observed_scale"],metric["scale_xy"])):
                    raise RuntimeError("Viewport/transform matrix failed")
            if window["window_mode"] != 0 or fill["integer"] or not pixel["integer"] or self.app.returncode != 0:
                raise RuntimeError("Window restore/stretch/clean exit matrix failed")
            if "ERROR:" in (self.out / "wine.log").read_text(errors="replace"):
                raise RuntimeError("Game emitted ERROR")
            return
        self.display_mode("Left", "fullscreen_fill")
        self.tap("Escape")
        self.tap("Return")
        self.tap("Down")
        self.tap("Return")
        self.tap("Return")
        # Existing QA slot 1 is overwritten by the actual confirmation dialog.
        self.sleep(2)
        if 0 not in self.samples:
            self.tap("Right")
            self.tap("Return")
        self.wait(lambda: 0 in self.samples, "new Normal-difficulty slot 1")
        self.sleep(2.1)
        self.key("d", True)
        self.sleep(.4)
        self.key("d", False)
        self.key("a", True)
        self.sleep(.4)
        self.key("a", False)
        self.wait(lambda: 15 in self.samples, "real stage time 15", 50)
        self.key("w",True)
        self.sleep(1.5)
        self.key("w",False)
        self.tap("q")
        first = self.wait(lambda: self.events["SONAR_TRACE"] and self.events["SONAR_TRACE"][0]["data"], "Q sonar activation")
        self.sleep(.5)
        self.shot("sonar-Q-pulse")
        self.key("z", True)
        cd8 = self.wait(lambda: next((e["data"] for e in self.events["SONAR_STATE"]
                                     if e["data"]["world_time"] >= first["world_time"]
                                     and math.ceil(e["data"]["cooldown"]) == 8), None), "08 s sonar cooldown")
        self.shot("sonar-cooldown-08")
        count = len(self.events["SONAR_TRACE"])
        self.tap("q")
        self.sleep(.35)
        if len(self.events["SONAR_TRACE"]) != count:
            raise RuntimeError("Q activated sonar during cooldown")
        ready = self.wait(lambda: next((e["data"] for e in self.events["SONAR_STATE"]
                                       if e["data"]["world_time"] > cd8["world_time"]
                                       and e["data"]["cooldown"] == 0), None), "sonar ready", 25)
        self.shot("sonar-ready")
        if cd8.get("text") != "08 s" or ready.get("text") != "LISTO":
            raise RuntimeError("Sonar HUD status did not reach 08 s and LISTO")
        self.key("z", False)
        self.tap("Escape")
        self.tap("Down")
        self.tap("Return")
        self.tap("Down", 7)
        self.tap("Return")
        self.tap("Down", 14)
        self.tap("Return")
        self.tap("e")
        self.shot("sonar-bindings-E")
        if json.loads(self.pref.read_text()).get("bindings", {}).get("key:sonar") != ord("E"):
            raise RuntimeError("Actual controls UI did not persist sonar E binding")
        self.tap("Escape")
        self.tap("Escape")
        self.tap("Return")
        self.key("z", True)
        self.sleep(5)
        self.tap("e")
        second = self.wait(lambda: len(self.events["SONAR_TRACE"]) >= 2 and self.events["SONAR_TRACE"][1]["data"], "rebound E sonar")
        self.sleep(.5)
        self.shot("sonar-E-pulse")
        self.wait(lambda: 40 in self.samples, "real stage time 40", 40)
        self.key("z", False)
        self.tap("Escape")
        self.tap("Down")
        self.tap("Return")
        self.tap("Down", 3)
        self.display_mode("Right", "fullscreen_pixel")
        self.display_mode("Right", "window1")
        window = self.display_mode("Right", "window2")
        self.shot("window2-options")
        self.tap("Escape")
        self.tap("Down", 3)
        self.tap("Return")
        self.tap("Right")
        self.tap("Return")
        self.shot("title-after-play")
        self.tap("Down", 4)
        self.tap("Return")
        self.tap("Right")
        # No pump after confirmation: the expected clean process exit is success.
        self.key("Return", True)
        time.sleep(.08)
        self.key("Return", False)
        self.app.wait(timeout=12)
        self.report["display_checks"] = {"window3": adjusted, "fill": fill, "pixel": pixel, "window2": window}
        self.report["sonar_checks"] = {"Q": first, "cooldown_08": cd8, "ready": ready, "E": second,
                                       "cooldown_retrigger_rejected": True, "binding_persisted": True}
        if self.app.returncode != 0:
            raise RuntimeError(f"Unclean game exit: {self.app.returncode}")
        if set(self.samples) != TARGETS:
            raise RuntimeError("Incomplete runtime samples")
        for target, sample in self.samples.items():
            if sample["os"] != "Windows" or sample["elapsed"] < target or sample["world_time"] < target:
                raise RuntimeError(f"Invalid Windows/runtime evidence: {sample}")
            if not all(sample[k] for k in ("stage_system", "weapon_system", "boss_system")):
                raise RuntimeError("Missing real gameplay systems")
        last = self.samples[40]
        if last["regular_spawned"] < 4 or last["regular_kills"] < 1 or not any(s["enemies"] > 0 for s in self.samples.values()):
            raise RuntimeError("No evidence of real enemies, spawning and kills")
        if not any(s["enemy_bullets"] > 0 for s in self.samples.values()):
            raise RuntimeError("No real enemy bullet evidence")
        if len(self.events["SONAR_TRACE"]) != 2 or first["key"] != "Q" or second["key"] != "E":
            raise RuntimeError("Expected exactly two real sonar activations: Q and E")
        for activation in (first, second):
            if activation["cooldown"] != 12 or activation["remaining"] != 4 or not activation["informational_only"]:
                raise RuntimeError("Sonar duration/cooldown contract failed")
        for metric, mode in ((fill, 4), (pixel, 4), (window, 0)):
            if metric["window_mode"] != mode or metric["clipped"]:
                raise RuntimeError("Display mode/clipping policy failed")
        for metric in (fill, pixel):
            if metric["screen_size"] != [self.width, self.height] or metric["window_size"] != [self.width, self.height]:
                raise RuntimeError("Fullscreen does not occupy the actual physical desktop")
        for metric in (fill, pixel, window):
            if any(abs(a - b) > .005 for a, b in zip(metric["observed_scale"], metric["scale_xy"])):
                raise RuntimeError("Observed viewport scale differs from display metrics")
        if fill["integer"] or not pixel["integer"] or not window["integer"]:
            raise RuntimeError("Fill/pixel/window stretch policy failed")
        if "ERROR:" in (self.out / "wine.log").read_text(errors="replace"):
            raise RuntimeError("Game emitted ERROR; inspect complete logs")

    def close(self):
        errors = []
        for name in list(self.held):
            try:
                self.key(name, False)
            except Exception as error:
                errors.append(str(error))
        if self.recorder:
            try:
                self.recorder.communicate(b"q", timeout=15)
                if self.recorder.returncode != 0:
                    errors.append(f"ffmpeg exited {self.recorder.returncode}")
            except Exception as error:
                self.recorder.kill()
                self.recorder.wait()
                errors.append(str(error))
        if self.app and self.app.poll() is None:
            self.app.terminate()
            try:
                self.app.wait(timeout=10)
            except subprocess.TimeoutExpired:
                self.app.kill()
                self.app.wait()
        for stream in self.streams:
            stream.close()
        if self.display:
            self.x.XCloseDisplay(self.display)
        self.report.update(events=self.events, samples=self.samples,
                           wall_seconds=time.monotonic() - self.started,
                           exit_code=self.app.returncode if self.app else None)
        if errors:
            self.report["cleanup_errors"] = errors
            self.report["passed"] = False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exe", type=Path, required=True)
    parser.add_argument("--wine", default="/workspace/tools/wine/usr/lib/wine/wine64")
    parser.add_argument("--prefix", type=Path, default=Path("/workspace/rescue-qa/wine-ready"))
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--display", default=":91")
    parser.add_argument("--display-only", action="store_true", help="Menus and fullscreen matrix only; no claim of gameplay validation")
    parser.add_argument("--cache", type=Path, default=Path("/workspace/04a-qa/cache"))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    report = {"passed": False, "executable": str(args.exe.resolve()),
              "host": "Linux/Wine compatibility layer; NOT physical Windows",
              "capture": "Entire virtual XRandR desktop; actual Windows PE under Wine and X11 keyboard input",
              "visual_review_required": "Review full-screen t12/t15/t20 and sonar pulse images for ordinary groups versus loot badges; no visual classifier is claimed."}
    session = None
    try:
        report["sha256"] = hashlib.sha256(args.exe.read_bytes()).hexdigest()
        if args.exe.read_bytes()[:2] != b"MZ":
            raise RuntimeError("--exe is not a Windows PE executable")
        if "docs" in args.cache.resolve().parts:
            raise RuntimeError("QA cache must remain outside docs")
        session = Session(args, report)
        session.run()
        report["passed"] = True
    except Exception as error:
        report["failure"] = f"{type(error).__name__}: {error}"
        if session and session.window:
            try:
                session.shot("failure")
            except Exception as capture_error:
                report["failure_capture_error"] = str(capture_error)
    finally:
        if session:
            session.close()
        (args.output / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
