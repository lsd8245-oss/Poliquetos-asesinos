"""Conservative maximum-reachable-build damage envelope; preserve original HP as vida_base.
This is a lower kill-time check, not a claim about a human's accuracy or 90min playtime.
Budgets exclude optional coins from max-level bubbles/phase changes; reports say so.
"""
import csv,itertools,json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(n):return json.loads((ROOT/f'data/{n}.json').read_text())
def main():
    worlds,bosses,combat,shop=map(read,['worlds','bosses','combat','shop'])
    upgrades={x['id']:x for x in shop['mejoras']}
    reports=[];income=0
    for world in worlds:
        n=world['id'];level=min(8,1+3*n)
        shot=combat['shot'][level-1];missile=combat['missile'][level-1];bomb=combat['bomb'][level-1]
        groups=world['sectores_jefes'] if n==14 else [{'id':0,'jefes':world['jefes'],'objetivo_seg':world['jefe_objetivo_seg'],'base_monedas':world['base_monedas']}]
        for group in groups:
            target=float(group['objetivo_seg'])*combat['boss']['minimum_time_fraction']
            rows=[b for b in bosses if b['id'] in group['jefes']]
            original=sum(b.get('vida_base',b['vida']) for b in rows)
            gap=0 if len(rows)>1 else (len(rows[0]['fases'])-1)*combat['timings']['phase_invulnerability']
            best=None
            for damage,rate,bombs_rank,rov,multi in itertools.product(range(6),range(5),range(4),range(2),range(2)):
                if n<10 and (rov or multi):continue
                cost=sum(upgrades['dano']['costos'][:damage])+sum(upgrades['cadencia']['costos'][:rate])+sum(upgrades['bombas']['costos'][:bombs_rank])+rov*1500+multi*1300
                if cost>income:continue
                dmg=1+damage*.12;cad=1+rate*.1
                dps=(shot['dps']+missile['dps'])*dmg*cad+rov*shot['dps']*.3*dmg*cad+multi*(4*shot['damage']*3/6)*dmg
                bomb_burst=(2+bombs_rank)*bomb['damage']*.5*dmg
                # Easiest mode reduces bossHP .85; no phase-lock credit for groups
                # because another participant can take damage during a partner's lock.
                hp_needed=(dps*2*max(0,target-gap)+bomb_burst)/combat['difficulty']['easy']['boss_hp']
                if best is None or hp_needed>best['required_hp']:
                    best={'required_hp':hp_needed,'dps':dps,'bomb_burst':bomb_burst,'ranks':{'dano':damage,'cadencia':rate,'bombas':bombs_rank},'rov':bool(rov),'multicorer':bool(multi),'cost':cost}
            tuned=max(original,math.ceil(best['required_hp'])+len(rows))
            allocated=0
            for i,b in enumerate(rows):
                base=b.get('vida_base',b['vida']);b['vida_base']=base
                hp=tuned-allocated if i==len(rows)-1 else math.ceil(tuned*base/original)
                b['vida']=hp;allocated+=hp
            reports.append({'world':n,'group':group['id'],'boss_ids':group['jefes'],'target_seconds':group['objetivo_seg'],'minimum_seconds':target,'budget':income,'weapon_level_bound':level,'base_hp':original,'tuned_hp':allocated,'transition_gap':gap,'max_build':best,'normal_continuous_lower_seconds':max(0,(allocated-best['bomb_burst'])/(best['dps']*2))+gap})
            income+=group['base_monedas']*1.2
    (ROOT/'data/bosses.json').write_text(json.dumps(bosses,ensure_ascii=False,indent=2)+'\n')
    result={'assumption':'Reachable build envelope from nominal no-death prior income; max-level/phase bonus coin income may permit stronger builds. Human playtime not measured.','nominal_target_seconds':5400,'nominal_minimum_seconds':4212,'encounters':reports}
    (ROOT/'data/balance_report.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    with (ROOT/'docs/boss_balance.csv').open('w') as f:
        fields=['world','group','target_seconds','minimum_seconds','budget','weapon_level_bound','base_hp','tuned_hp','normal_continuous_lower_seconds']
        writer=csv.DictWriter(f,fieldnames=fields,extrasaction='ignore');writer.writeheader();writer.writerows(reports)
    print(f'{len(reports)} encounters calibrated; nominal base budget excludes optional coin bonuses; min-time tests required.')
if __name__=='__main__':main()
