"""05A exported-PE session with real X11 keys and read-only runtime telemetry.

Automated controls, not a human difficulty playtest. Does not change Game,
health, currency, clock, boss HP, weapons or victory conditions. Dedicated QA
Wine prefix only. Raw recording is kept outside docs and compressed separately.
"""
import argparse
import importlib.util
import json
import math
import os
from pathlib import Path
import subprocess
import time
import hashlib

spec = importlib.util.spec_from_file_location('qa04a', Path(__file__).with_name('qa-04a-windows.py'))
base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)
base.TRACE_TYPES = (*base.TRACE_TYPES, 'CAMPAIGN_QA_TRACE')


class CampaignSession(base.Session):
    def guard(self):
        if time.monotonic() - self.started > 1000:
            raise RuntimeError('1000 second session limit')
        if self.app is not None and self.app.poll() is not None:
            raise RuntimeError(f'Unexpected PE exit: {self.app.returncode}')

    def wait(self, condition, description, timeout=30):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            self.pump()
            value = condition()
            if value:
                return value
            time.sleep(.04)
        raise RuntimeError('Timed out: ' + description)

    @property
    def frame(self):
        records = self.events['CAMPAIGN_QA_TRACE']
        return records[-1]['data'] if records else {}

    def choose(self, action):
        self.wait(lambda: action in self.frame.get('buttons', []), 'UI action ' + action)
        current = self.frame
        buttons = current['buttons']
        distance = (buttons.index(action) - current['selected']) % len(buttons)
        if distance:
            self.tap('Down', distance)
        self.tap('Return')
        self.sleep(.15)

    def movement(self, dx=0, dy=0):
        wanted = set()
        if dx > 0: wanted.add('d')
        if dx < 0: wanted.add('a')
        if dy > 0: wanted.add('s')
        if dy < 0: wanted.add('w')
        for name in ('w', 'a', 's', 'd'):
            if (name in wanted) != (name in self.held):
                self.key(name, name in wanted)

    @staticmethod
    def control(frame, previous):
        """Choose keyboard direction by short-horizon collision/aim estimates."""
        px, py = frame['player']
        aim_x, aim_y = 90, 168
        enemies = frame['enemies']
        visible = [e for e in enemies if e['pos'][0] > px + 24]
        if visible:
            target = min(visible, key=lambda e: (not e['boss'], e['pos'][0]))
            rectangles = target['rects'] or [[target['pos'][0]-target['size'][0]/2,
                                             target['pos'][1]-target['size'][1]/2, *target['size']]]
            rect = min(rectangles, key=lambda r: r[0])
            aim_y = rect[1] + rect[3] / 2
        pickups = []
        for drop in frame['drops']:
            x, y = drop['pos']
            if 20 < x < 290 and 16 < y < 320:
                priority = 0
                if drop['kind'] in ('amarillo', 'shield') and frame['shield'] < 85: priority = 10
                elif drop['kind'] in ('rojo', 'verde', 'azul'): priority = 6
                elif drop['kind'] == 'coin': priority = 1
                if priority: pickups.append((priority, -math.hypot(x-px, y-py), x, y))
        if pickups:
            priority, _, x, y = max(pickups)
            if priority > 1 or not visible:
                aim_x, aim_y = min(190, x), y
        speed = float(frame.get('speed', 160))
        old_enemies = {e['uid']: e for e in previous.get('enemies', [])}
        delta = max(.03, frame['elapsed']-previous.get('elapsed', frame['elapsed']-.12))
        choices = []
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                length = math.hypot(dx, dy) or 1
                vx, vy = dx*speed/length, dy*speed/length
                endx, endy = max(10, min(630, px+vx*.2)), max(14, min(322, py+vy*.2))
                score = abs(endy-aim_y)*.12 + abs(endx-aim_x)*.04
                for t in (.10, .22, .4, .6):
                    qx, qy = max(10, min(630, px+vx*t)), max(14, min(322, py+vy*t))
                    for x, y, bx, by, sx, sy in frame['bullets']:
                        ex, ey = x+bx*t, y+by*t
                        if abs(ex-qx)>70 or abs(ey-qy)>70: continue
                        distance = ((ex-qx)/(sx/2+9))**2 + ((ey-qy)/(sy/2+6))**2
                        score += 200/(distance+.15)
                        if distance < 1: score += 12000
                    for enemy in enemies:
                        prior = old_enemies.get(enemy['uid'], enemy)
                        ex = max(-500, min(500, (enemy['pos'][0]-prior['pos'][0])/delta))
                        ey = max(-500, min(500, (enemy['pos'][1]-prior['pos'][1])/delta))
                        for x, y, w, h in enemy['rects']:
                            rx, ry = x+ex*t, y+ey*t
                            gapx = max(rx-qx, qx-rx-w, 0)
                            gapy = max(ry-qy, qy-ry-h, 0)
                            if gapx<10 and gapy<6: score += 18000
                            if gapx<50 and gapy<40: score += 120/(1+gapx+gapy)
                choices.append((score, dx, dy))
        _, dx, dy = min(choices)
        return dx, dy

    def check_disk_save(self, expected):
        edition = expected['edition']
        roots = list(self.args.prefix.glob('drive_c/users/*/AppData/Roaming/Poliquetos Asesinos'))
        path = roots[0]/edition/'campaign12/slot_1.json'
        if not path.is_file(): raise RuntimeError('Current campaign save was not written')
        saved = json.loads(path.read_text())
        for field in ('world', 'seed'):
            if saved.get(field) != expected.get(field):
                raise RuntimeError('Disk save differs from live ' + field)
        if saved.get('version') != 3 or saved.get('upgrades') != expected.get('upgrades'):
            raise RuntimeError('Disk save version or purchases differ from live state')
        self.report.setdefault('disk_saves', []).append({'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'profile': saved})

    def play_world_one(self):
        self.wait(lambda: self.frame.get('screen') == 'game', 'real W01 entry')
        self.key('z', True)
        previous = self.frame
        seen = -1
        marks = set()
        started = time.monotonic()
        bomb_clock = -10.0
        while time.monotonic()-started < 700:
            self.pump()
            frame = self.frame
            if len(self.events['CAMPAIGN_QA_TRACE']) == seen:
                time.sleep(.025)
                continue
            seen = len(self.events['CAMPAIGN_QA_TRACE'])
            if frame.get('minis', 0) or any(e['mini'] for e in frame.get('enemies', [])):
                raise RuntimeError('A disabled miniboss appeared')
            if frame.get('world') != 1:
                raise RuntimeError('W01 advanced before UI confirmation')
            for mark in (10, 60, 73, 120, 169):
                if frame['world_time'] >= mark and mark not in marks:
                    self.shot('stage-%03d' % mark)
                    marks.add(mark)
            for enemy in frame.get('enemies', []):
                if enemy['boss'] and enemy['phase'] not in marks:
                    self.shot('boss-phase-%d' % enemy['phase'])
                    marks.add(enemy['phase'])
            if frame.get('screen') == 'dead':
                self.shot('failed-real-death')
                raise RuntimeError('Pilot died; preserve failed recording and improve controls, not stats')
            if frame.get('screen') in ('results', 'rest'):
                self.movement()
                self.key('z', False)
                if frame['boss_spawns'] < 1 or frame['state'] not in ('results', 'rest'):
                    raise RuntimeError('No actual final boss victory')
                self.report['victory_frame'] = frame
                self.shot('real-boss-victory')
                self.wait(lambda: self.frame['screen'] == 'rest', 'post-boss rest')
                return
            dx, dy = self.control(frame, previous)
            self.movement(dx, dy)
            now = time.monotonic()
            if frame.get('bombs', 0) > 0 and now-bomb_clock>4 and len(frame['bullets'])>12:
                self.key('x', True)
                bomb_clock = now
            elif 'x' in self.held:
                self.key('x', False)
            previous = frame
        raise RuntimeError('W01/boss timeout; no victory injected')

    def quit_from_title(self):
        self.choose('quit')
        self.wait(lambda: self.frame.get('screen') == 'confirm', 'quit confirmation')
        current = self.frame
        target = current['buttons'].index('accept_confirm')
        self.tap('Right', (target-current['selected']) % len(current['buttons']))
        self.key('Return', True)
        time.sleep(.08)
        self.key('Return', False)
        self.app.wait(timeout=15)
        if self.app.returncode != 0: raise RuntimeError('Unclean exit')

    def relaunch(self):
        offset = len(self.events['CAMPAIGN_QA_TRACE'])
        self.app = subprocess.Popen(self.report['command'], cwd=self.args.exe.resolve().parent,
                                    env=self.env, stdout=self.streams[0], stderr=subprocess.STDOUT)
        self.wait(lambda: len(self.events['CAMPAIGN_QA_TRACE'])>offset and self.frame.get('screen')=='splash', 'fresh process splash telemetry', 45)
        def opened():
            try:
                self.focus()
                return True
            except RuntimeError:
                return False
        self.wait(opened, 'fresh Windows window', 35)
        self.tap('Return')
        self.wait(lambda: self.frame.get('screen') == 'title', 'fresh title')

    def run(self):
        self.prepare()
        self.launch()
        self.wait(lambda: self.frame, 'read-only PE campaign telemetry')
        if self.frame.get('os') != 'Windows': raise RuntimeError('Expected actual Windows PE telemetry')
        self.choose('options')
        self.wait(lambda: self.frame['screen'] == 'options', 'options')
        current = self.frame
        target = current['buttons'].index('option:screen')
        self.tap('Down', (target-current['selected']) % len(current['buttons']))
        self.display_mode('Right', 'window3')
        self.display_mode('Right', 'fullscreen_fill')
        self.shot('fill-options')
        self.display_mode('Right', 'fullscreen_pixel')
        self.shot('pixel-options')
        self.display_mode('Left', 'fullscreen_fill')
        self.tap('Escape')
        if 'pruebas' in self.args.exe.name.lower():
            self.choose('sandbox')
            for world in range(1, 14):
                self.wait(lambda: self.frame.get('selector_world') == world, 'selector ' + str(world))
                self.shot('selector-%02d' % world)
                self.choose('dev_world')
            # Pruebas explicitly offers weapon levels. Select through its real UI;
            # equipment/upgrades stay unpurchased and damage rules remain unchanged.
            for weapon in ('shot', 'missile', 'bomb'):
                for _ in range(7): self.choose('dev_weapon:' + weapon)
            self.shot('explicit-level-eight-weapons')
            self.report['explicit_selector_weapon_levels'] = {'shot': 8, 'missile': 8, 'bomb': 8}
            self.choose('dev_start')
        else:
            self.choose('new')
            self.choose('difficulty:normal')
            self.choose('slot:1')
            self.sleep(.5)
            if self.frame.get('screen') == 'confirm': self.choose('accept_confirm')
        self.wait(lambda: self.frame.get('screen')=='game' and self.frame.get('seed') is not None and self.frame.get('profile_version')==3, 'new live campaign seed')
        if 'pruebas' not in self.args.exe.name.lower(): self.check_disk_save(self.frame)
        self.play_world_one()
        before = self.frame
        self.choose('shop')
        self.shot('shop-after-victory')
        item = 'escudo_max' if before['credits'] >= 250 else 'iman'
        self.choose('inspect:upgrade:' + item)
        self.choose('buy')
        self.sleep(.4)
        purchased = self.frame
        if purchased['upgrades'].get(item, 0) != before['upgrades'].get(item, 0)+1:
            raise RuntimeError('Real purchase did not apply')
        self.report['purchase'] = {'item': item, 'before': before['credits'], 'after': purchased['credits']}
        self.choose('rest')
        self.choose('save')
        self.choose('manual:1')
        self.check_disk_save(self.frame)
        self.shot('saved-after-purchase')
        self.choose('rest')
        self.choose('leave')
        self.choose('accept_confirm')
        self.quit_from_title()
        self.relaunch()
        self.choose('load')
        self.choose('slot:1')
        self.wait(lambda: self.frame.get('screen') == 'rest', 'real rest after close/reopen')
        restored = self.frame
        if (restored['world'] != 1 or restored['upgrades'] != purchased['upgrades']
                or restored['seed'] != purchased['seed'] or restored['credits'] != purchased['credits']):
            raise RuntimeError('Purchase or progress was lost on restart')
        self.shot('restored-after-restart')
        self.choose('next')
        self.wait(lambda: self.frame.get('world') == 2 and self.frame.get('screen') == 'game', 'real W02 transition after final victory')
        self.shot('w02-entry-no-development')
        self.report['restored_frame'] = restored
        self.report['next_world_frame'] = self.frame
        self.tap('Escape')
        self.choose('leave')
        self.choose('accept_confirm')
        self.quit_from_title()
        self.report['real_route_passed'] = True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--wine', default='/workspace/tools/wine/usr/lib/wine/wine64')
    parser.add_argument('--prefix', type=Path, default=Path('/workspace/rescue-qa/wine-ready'))
    parser.add_argument('--display', default=':92')
    parser.add_argument('--cache', type=Path, default=Path('/workspace/05a-qa/cache'))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    report = {'passed': False, 'host': 'Windows PE under Wine/Linux, NOT physical Windows',
              'controls': 'Automated X11 keyboard, read-only telemetry; no forced damage, HP, time, money or victory',
              'sha256': hashlib.sha256(args.exe.read_bytes()).hexdigest()}
    session = None
    try:
        session = CampaignSession(args, report)
        session.run()
        if any(marker in (args.output/'wine.log').read_text(errors='replace') for marker in ('ERROR:', 'SAVE_DIAGNOSTIC ')):
            raise RuntimeError('Windows runtime emitted an error; inspect complete log')
        report['passed'] = True
    except Exception as error:
        report['failure'] = f'{type(error).__name__}: {error}'
        if session and session.window:
            try: session.shot('failure')
            except Exception: pass
    finally:
        if session: session.close()
        (args.output/'report.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps({k: v for k, v in report.items() if k not in ('events', 'samples')}, indent=2))
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
