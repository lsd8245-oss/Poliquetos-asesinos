"""Deterministic native campaign source. Regenerate JSON with --seed (default 20261101)."""
import argparse
import json
import math
from pathlib import Path
import random
import re

ROOT = Path(__file__).resolve().parents[1]
COUNTS = [90,125,135,135,135,150,150,162,162,200,200,245,285,250]
TIMES = [180]*4+[210]*4+[240]*4+[270,330]
TARGETS = [90,90,90,105,105,105,120,135,120,120,120,120,150,510]
HP = [1750,2100,2450,3300,3700,4100,5150,6300,6100,6550,7000,7500,9950]
MINI_HP = [975,1170,1365,1560,1755,1950,2145,2340,2535,2730,2925,3120,3315,3510]
MINIS = ['pision','arenicola','oenone','myxicola','spirobranchus','glycera','terebellides','lumbrineris','lopado','flabegraviera','chryso','paralvinella','aphro','mech_nereis']
PALETTES = [['#7fd8f0','#2bb5c9','#f5f1d0'],['#efd480','#39c7c3','#fff5bd'],['#647d8e','#567445','#ef975e'],['#225f39','#74973b','#dfaa47'],['#dc429d','#f17b36','#225abc'],['#8dcc38','#14885a','#c6df75'],['#72573d','#6c7140','#ad884d'],['#80a52e','#703f91','#223c2e'],['#10285a','#39d9e3','#63ef9c'],['#f0fbff','#77b7db','#586ed9'],['#a7a59d','#a3493b','#e6c58c'],['#15141c','#dd3a27','#f09236'],['#0e0b1d','#795fa1','#68adb8'],['#787f86','#e1e9e3','#65f567']]
HAZARDS = [['boyas','cascos'],['conchas','rocas'],['corriente_marea'],['kelp'],['corales'],['corriente_hojas'],['raices'],['barriles','petroleo'],['medusas'],['icebergs','granizo'],['costillas'],['geiseres','lava'],[],['laseres','compuertas','cintas','torretas']]
SONGS = ['Nereida Vuelve a Desgarrar','Capitélido del Arenal','Polinoideo de Hierro','Reina de los Tentáculos','Gusano de Fuego','Hoja entre las Hojas','Orbiniidae, sal de ahí','Zona muerta','en_proceso','en_proceso','Osedax','en_proceso','en_proceso','en_proceso']
FORMATIONS = ['linea_vertical','linea_horizontal','v','v_invertida','zigzag','circulo','doble_columna','ambos_lados','diagonal']
PROFILES = [
 ('nereis','Nereidae',[180,120],[['ondular_vertical','balas_apuntadas_3'],['faringe_embestida','abanico_5'],['dividir_en_dos','anillo_12']]),
 ('capit','Capitelidae',[200,140],[['columnas_arena'],['cabeza_ganchos_abanico'],['tormenta_arena','embestida_diagonal']]),
 ('polyn','Polinoidae',[200,140],[['escamas_rebote'],['elitros_bloquean'],['carga_blindada','lluvia_piedras']]),
 ('tere','Terebellidae',[240,180],[['tentaculos_barrido_8'],['tentaculos_agarre'],['mucosidad','rafaga_boca']]),
 ('hermo','Hermodice carunculata',[220,140],[['cerdas_abanico_7'],['enroscar_coral','embestida'],['lluvia_cerdas','anillo_expansivo']]),
 ('leafqueen','Phyllodocidae',[220,140],[['camuflaje_hojas','falsos_blancos'],['hojas_cortantes'],['hojas_guiadas','ondulacion_total']]),
 ('orbin','Orbiniidae',[240,160],[['brotes_fango'],['gas_toxico'],['embestida','raices_caen']]),
 ('tomo','Tomopteridae',[260,140],[['luces_guiadas'],['semitransparencia'],['destello','rayos_cian']]),
 ('eulagisca','Eulagisca gigantea',[260,160],[['estalactitas'],['escamas_orbita'],['tormenta_nieve','embestida_congelante']]),
 ('osedax','Osedax',[300,200],[['raices_hueso'],['machos_enjambre'],['acido_expansivo']]),
 ('alvinella','Alvinella pompejana',[300,200],[['geiseres_fuego'],['lava_ascendente'],['columnas_magma','abanico_brasas']]),
 ('hadalsovereign','Macellicephaloides grandicirra',[200,120],[['orbita_embestida'],['escamas'],['furia_hadal']]),
 ('riftia','Riftia pachyptila',[160,300],[['penacho_abanico'],['anillos'],['penacho_furia']]),
 ('pollutionCapit','Capitella capitata',[120,80],[['crias_carril'],['parejas_cruzadas'],['furia_contaminacion','patrones_tres']]),
 ('pollutionSpio','Streblospio benedicti',[140,90],[['palpos_bumeran'],['parejas_cruzadas'],['furia_contaminacion','patrones_tres']]),
 ('pollutionCirrat','Cirriformia tentaculata',[160,100],[['cirros_barrido'],['parejas_cruzadas'],['furia_contaminacion','patrones_tres']]),
 ('robot_pinza','Robot Pinza',[140,140],[['pinza_individual'],['robots_parejas'],['fusion_robot']]),
 ('robot_torreta','Robot Torreta',[140,140],[['torreta_individual'],['robots_parejas'],['fusion_robot']]),
 ('robot_taladro','Robot Taladro',[140,140],[['taladro_individual'],['robots_parejas'],['fusion_robot']]),
 ('epitoke','Epitoca',[220,140],[['gusano_ondas'],['transformacion_epitoca'],['nubes_gametos','orbita']]),
 ('scientist','Científico',[200,200],[['drones','laseres_sala'],['criaturas_tanques'],['mecha_brazos']]),
 ('euniceTitan','Eunice aphroditois',[320,300],[['antenas','mandibulas_suelo'],['segmentos_horizontales'],['mandibulas_dobles','escombros'],['furia_anillos_mandibulas']]),
]
PROFILE = {p[0]:p for p in PROFILES}


def snake(key):
    return re.sub(r'(?<!^)(?=[A-Z])','_',key).lower()


def equal_split(total, keys):
    return {k:total//len(keys)+(i<total%len(keys)) for i,k in enumerate(keys)}


def body_profile(name):
    if any(k in name for k in ['Syllidae','Spionidae','Cirratulidae','Ctenodrilidae','Protodril']): return 'enjambre','enjambre','M2','F1',24
    if any(k in name for k in ['Serpulidae','Sabellidae','Fabriciidae','Terebell','Trichobranch','Chaetopter','Sabellari','Pectinari','Onuph','Oweni','Ampharet','Riftia','Paralvinella','Amphisamytha']): return 'tubicola','mediano','M5','F3',48
    if any(k in name for k in ['Arenicol','Capitell','Opheli','Orbini','Cossur','Maldan','Scalibreg','Sternasp','Paraon','Magelon']): return 'cavador','pequeno','M6','F5',32
    if any(k in name for k in ['Alciop','Tomopter','Lopador','Typhlo','Poeob','Pontod','Iospil','Acrocirr']): return 'pelagico','pequeno','M8','F4',32
    if any(k in name for k in ['Polyno','Aphrodi','Sigalion','Acoet','Eulepeth','Pholo','Chrysopet','Euphros']): return 'escamoso','mediano','M7','F2',48
    if any(k in name for k in ['Phyllod','Nepht','Glycer','Goniad','Hesion','Lumbriner','Oenon','Arabell','Dorville','Pilarg']): return 'errante','pequeno','M3','F2',32
    return 'otro','pequeno','M4','F1',32


def hazard_data():
    base={'damage':20,'width':48,'height':56,'duration':12,'telegraph':.5,'scroll':True,'effect':'damage','placement':'scroll','anchor_y':'event','spawn_offset':10,'push_x':0,'push_y':0,'slow':0,'cycle':0,'active_duration':12,'explosive':False}
    overrides={
        'solid':{},'boyas':{},'cascos':{'width':64,'height':48},
        'conchas':{'anchor_y':'bottom','height':28},'rocas':{'anchor_y':'bottom','height':36},
        'corriente_marea':{'damage':0,'width':640,'height':336,'push_y':30,'reverse_every':10,'duration':10,'scroll':False,'placement':'fixed','anchor_y':'top','effect':'push'},
        'kelp':{'damage':0,'slow':.3,'effect':'slow'},
        'corales':{'anchor_y':'bottom','height':76},
        'corriente_hojas':{'damage':0,'width':640,'height':336,'push_x':-20,'duration':10,'scroll':False,'placement':'fixed','anchor_y':'top','effect':'push'},
        'raices':{'anchor_y':'top','height':76},
        'barriles':{'blast_radius':70,'enemy_damage':60,'explosive':True},
        'petroleo':{'damage':0,'slow':.25,'effect':'slow'},
        'medusas':{'width':40,'height':48},'icebergs':{'anchor_y':'bottom','height':76},
        'granizo':{'damage':10,'width':10,'height':336,'duration':6,'active_duration':.5,'scroll':False,'placement':'random','anchor_y':'top','random_x':[0,600]},
        'costillas':{'anchor_y':'bottom','height':76},
        'geiseres':{'width':28,'height':106,'telegraph':1,'active_duration':3,'scroll':False,'placement':'random','anchor_y':'bottom','random_x':[60,600]},
        'lava':{'width':640,'height':12,'telegraph':1,'scroll':False,'placement':'fixed','anchor_y':'bottom'},
        'laseres':{'width':28,'height':336,'cycle':3,'active_duration':1,'scroll':False,'placement':'random','anchor_y':'top','random_x':[60,600]},
        'compuertas':{'width':28,'height':240,'cycle':4,'active_duration':1.5,'scroll':False,'placement':'random','anchor_y':'top','random_x':[200,580]},
        'cintas':{'damage':0,'width':640,'height':336,'push_x':-30,'duration':10,'scroll':False,'placement':'fixed','anchor_y':'top','effect':'push'},
        'torretas':{'width':48,'height':48,'anchor_y':'top'},
        'escombros':{'width':24,'height':336,'active_duration':.4,'scroll':False,'placement':'random','anchor_y':'top','random_x':[0,600]},
        'corrientes':{'damage':0,'width':640,'height':336,'push_y':35,'duration':10,'scroll':False,'placement':'fixed','anchor_y':'top','effect':'push'},
    }
    return {key:base|values for key,values in overrides.items()}


def combat_data():
    c = {'screen':{'width':640,'height':360,'play_height':336,'hud_height':24},
         'player':{'sprite_size':[48,24],'hitbox':[10,6],'speed':160,'shield':100,'damage_invulnerability':1,'respawn_invulnerability':2,'start_pos':[80,168],'initial_bombs':2,'max_bombs':5,'max_weapon_level':8,'magnet_radius':24},
         'timings':{'bomb_cooldown':1.5,'boss_entry':3,'boss_defeat':3,'phase_invulnerability':3,'strong_telegraph':.5,'alert':6,'death_explosion':1.2,'death_fade':.5,'pause_resume':3,'checkpoint_notice':2,'intro':2,'retry_fade':.5,'regen_delay':5,'lab_room_line':2},
         'enemy':{'bullet_pool':200,'bullet_size':[6,6],'bullet_speed_base':90,'bullet_speed_world_scale':.04,'dps_ref_base':30,'dps_ref_world_step':6,'bullet_damage_base':10,'bullet_damage_world_step':.5,'contact_damage_base':20,'contact_damage_world_step':1,'boss_contact_base':30,'boss_contact_world_step':2,'hazard_damage':20,'speed':70,'swarm_hp_divisor':20,'small_hp_divisor':10,'medium_hp_multiplier':3,'escort_hp_multiplier':2,'armored_hp_multiplier':1.5,'bullet_ttl':12,'max_active':50,'spawn_margin':32},
         'items':{'pickup_radius':18,'speed':30,'shield_fraction':.25,'max_level_value':100,'small_coin':5,'large_coin':25,'radius':10,'magnet_speed':200},
         'boss':{'minimum_time_fraction':.4,'weak_multiplier':2,'body_multiplier':.5,'bomb_multiplier':.5,'phase_thresholds':[66,33],'mini_thresholds':[50],'miniboss_target':50,'entry_x':750,'arena_x':500,'lane_y':[70,168,266]},
         'scroll':{'normal':60,'escape':120,'parallax':[.1,.3,.6,1]},
         'shot':[],'missile':[],'bomb':[],
         'movement':{'M1':{'speed':70},'M2':{'speed':70,'amplitude':40,'frequency':2},'M3':{'speed':60,'pursuit_speed':30},'M4':{'speed':70,'entry_vertical_speed':80,'turn_after':1},'M5':{'scroll_multiplier':1,'anchor_y':304},'M6':{'telegraph':.5,'stay':3,'emerge_speed':100,'retreat_speed':80},'M7':{'speed':60,'stop_after':1,'telegraph':.5,'charge_speed':250,'charge_duration':2},'M8':{'speed':45,'radius':45,'angular_speed':2}},
         'fire_patterns':{'F0':{'interval':0,'count':0},'F1':{'interval':2,'count':1,'spread':0},'F2':{'interval':2.5,'count':1,'spread':0},'F3':{'interval':3,'count':3,'spread':.55},'F4':{'interval':4,'count':8,'spread':math.tau},'F5':{'interval':3,'count':3,'spread':0,'burst_interval':.15}},
         'formations':{'spacing_px':32,'spacing_seg':.3,'vertical_bounds':[24,312],'circle_radius':64,'zigzag_amplitude':40},
         'difficulty':{'easy':{'damage':.7,'boss_hp':.85,'bullet_speed':.9,'shield_items':1.3,'alert_checkpoint':True},'normal':{'damage':1,'boss_hp':1,'bullet_speed':1,'shield_items':1,'alert_checkpoint':False},'hard':{'damage':1.3,'boss_hp':1.15,'bullet_speed':1.1,'shield_items':.8,'alert_checkpoint':False}},
         'hazards':hazard_data(),
         'projectiles':{'shot_size':[8,4],'beam_size':[20,10],'missile_size':[12,6],'shot_ttl':2,'missile_ttl':4,'homing_turn_speed':4,'missile_floor_margin':10,'explosion_duration':.3,'pierce_damage_multiplier':1},
         'effects':{'damage_flash':.16,'large_shake':3,'small_shake':1,'shake_duration':.3,'escape_pulse_period':2,'escape_pulse_alpha':.18,'death_tip_count':20,'suggest_easy_deaths':5},
         'gear':{'net_capacity':5,'niskin_interval':20,'niskin_radius':140,'niskin_slow':.5,'niskin_boss_slow':.75,'niskin_duration':2,'multicorer_interval':6,'multicorer_count':4,'multicorer_damage':3,'rov_dps_fraction':.3,'rov_interval':.3,'lander_shield_fraction':.5,'deflector_width':32,'deflector_damage':5,'regen_delay':5,'grapple_speed':.25,'homing_turn':3,'enemy_homing_time':2,'magnet_speed':260},
         'friendly_projectile':{'ttl':3,'size':[10,4],'beam_size':[24,8],'spawn_offset':20},
         'ui':{'ending_seconds':4,'credits_seconds':8,'ending_rise':220,'flash_alpha':.55,'reduced_flash_alpha':.06}}
    for i,(dps,count,interval,pierce) in enumerate(zip([10,13,16,20,24,29,34,40],[1,2,3,3,4,4,5,6],[.25,.25,.25,.2,.2,.2,.2,.2],[0,0,0,0,1,2,2,3]),1):
        angles = [0] if count==1 else ([0,0] if count==2 else [(j-(count-1)/2)*.1 for j in range(count)])
        c['shot'].append({'level':i,'dps':dps,'count':count,'interval':interval,'damage':dps*interval/count,'speed':440,'angles':angles,'offsets_y':[-4,4] if count==2 else [0]*count,'pierce':pierce,'beam':i==8})
    for i,(dps,count) in enumerate(zip([4,6,8,10,12,14,17,20],[1,1,2,2,2,3,3,4]),1):
        c['missile'].append({'level':i,'dps':dps,'count':count,'interval':1,'damage':dps/count,'speed':140 if i==1 else 180,'homing':i>=5,'area':24 if i in [4,7,8] else 0,'arc_gravity':120,'launch_velocity_y':100,'directions':[-1,1] if count>=2 else [1]})
    for i,(radius,damage) in enumerate(zip([80,100,120,160,200,240,280,740],[50,80,120,170,230,300,380,500]),1): c['bomb'].append({'level':i,'radius':radius,'damage':damage,'full_screen':i==8})
    return c


def split_waves(n,limit):
    if not n: return []
    count = math.ceil(n/limit)
    if n//count<4: raise ValueError(f'Cannot split {n}')
    return [n//count+(i<n%count) for i in range(count)]


def phase_allocation(counts, unique, target):
    # Select exact 40% while avoiding fragments below the four-enemy wave minimum.
    states = {0:(0,[])}
    for key,total in counts.items():
        options = [n for n in range(total+1) if (n>=4 or n==0) and (total-n>=4 or n==total) and (key not in unique or n>=4)]
        next_states = {}
        for have,(cost,path) in states.items():
            for n in options:
                if have+n>target: continue
                nc = cost+(n-total*.4)**2
                if have+n not in next_states or nc<next_states[have+n][0]: next_states[have+n]=(nc,path+[n])
        states=next_states
    return dict(zip(counts,states[target][1]))


def make_waves(w,enemies,rng):
    unique,recurrent = w['unicos'],w['recurrentes']
    if w['id']==14:
        # Twenty-two seeded organic families, five individuals each. The whole eligible pool remains in worlds.json.
        selected = rng.sample(recurrent,22)
        counts = equal_split(140,unique)|equal_split(110,selected)
    else:
        uc = round(w['enemigos_total']*.6)
        counts = equal_split(uc,unique)|equal_split(w['enemigos_total']-uc,recurrent)
    first = phase_allocation(counts,unique,round(w['enemigos_total']*.4))
    events=[]
    for phase in [0,1]:
        pending=[]
        for key,total in counts.items():
            n=first[key] if phase==0 else total-first[key]
            for count in split_waves(n,20 if enemies[key]['categoria']=='enjambre' else 12): pending.append((key,count))
        # Cycle families across the stage instead of serializing each family.
        pending.sort(key=lambda x:(x[0] not in unique,unique.index(x[0]) if x[0] in unique else recurrent.index(x[0])))
        if phase: rng.shuffle(pending) if w['id']==14 else pending.sort(key=lambda x:((sum(map(ord,x[0]))%7),x[0]))
        for i,(key,count) in enumerate(pending):
            start = 10 if phase==0 else w['minijefe_inicio_seg']+60
            end = w['minijefe_inicio_seg']-1 if phase==0 else w['alerta_jefe_seg']-1
            t = start+(end-start)*i/max(1,len(pending))
            if key in recurrent: t=max(t,w['duracion_hasta_jefe_seg']*.25)
            events.append({'t':round(t,3),'tipo':'oleada','enemigo':key,'cantidad':count,'formacion':FORMATIONS[(i+phase*3)%len(FORMATIONS)],'y':[60,110,168,220,276][i%5],'portadora':False,'separacion_px':32,'separacion_seg':.3})
    events.sort(key=lambda e:e['t'])
    for i,color in enumerate(['rojo','verde','azul']*2):
        e=events[round(i*(len(events)-1)/5)]
        e.update(portadora=True,item=color)
    escort = unique[1]
    events += [{'t':w['minijefe_inicio_seg'],'tipo':'minijefe','id':w['minijefe'],'escoltas':{'enemigo':escort,'cantidad':2,'vida':2*math.ceil((30+6*(w['id']-1))/10),'tamano':[40,32]}},
               {'t':w['alerta_jefe_seg'],'tipo':'alerta_jefe','id':w['jefes'][0],'jefes':w['sectores_jefes'][0]['jefes'] if w['id']==14 else w['jefes']}]
    for t in [w['minijefe_inicio_seg']*.6,w['minijefe_inicio_seg']+65,w['alerta_jefe_seg']-2]: events.append({'t':t,'tipo':'escudo','item':'amarillo','y':168})
    for i,hazard in enumerate(w['peligros']):
        events.append({'t':25+i*12,'tipo':'peligro','id':hazard,'duracion_seg':10,'y':280 if i%2==0 else 40})
        events.append({'t':w['minijefe_inicio_seg']+70+i*8,'tipo':'peligro','id':hazard,'duracion_seg':10,'y':280 if i%2==0 else 40})
    return {'mundo':w['id'],'semilla':rng.seed_value if w['id']==14 else 0,'eventos':sorted(events,key=lambda e:e['t'])}


def make_boss(archetype,world,hp,target):
    _,name,size,patterns = PROFILE[archetype]
    thresholds = [100,66,33,15,0] if archetype=='euniceTitan' else [100,66,33,0]
    return {'id':f'boss_w{world:02}_{snake(archetype)}','nombre':name,'mundo':world,'arquetipo':archetype,'tipo':'jefe','vida':hp,'objetivo_seg':target,'minimo_seg':target*.4,'tamano':size,'segmentos':[{'id':'cabeza','hitbox':[0,size[1]*.3,size[0]*.25,size[1]*.4],'debil':True,'mult_dano':2},{'id':'cuerpo','hitbox':[size[0]*.25,0,size[0]*.75,size[1]],'debil':False,'mult_dano':.5}], 'fases':[{'desde_pct':a,'hasta_pct':b,'patrones':p} for a,b,p in zip(thresholds,thresholds[1:],patterns)],'recompensa_extra':0,'objeto_unico':{3:'coral',6:'abisal',9:'bioluminiscente',12:'magma'}.get(world),'parametros':{'intervalo':2,'telegraph':.5,'velocidad':80,'entrada_seg':3,'derrota_seg':3,'invulnerabilidad_fase_seg':3,'furia_cadencia':1.25 if world==8 else 1.3,'furia_velocidad':1.3,'polyn_apertura_seg':4,'tomo_visibilidad_seg':2,'destello_seg':.3,'estalactita_aviso_seg':.7,'congelacion_seg':1,'lava_subida_seg':10,'hermo_anillo_seg':5,'mucosidad_lento':.3}}


def build_campaign(seed=20261101):
    legacy=json.loads((ROOT/'data/legacy_inventory.json').read_text())
    entities={e['id']:e for e in legacy['entities']}
    worlds=[]; enemy_map={}; bosses=[]; waves={}
    robot = {'mech_syll':('Cablelarva','enjambre','M2','F0',24,'R1'),'mech_nereis':('Nereis Mk1','mediano','M3','F2',48,'R2'),'mech_sabel':('Torreta Sabélida','mediano','M5','F3',48,'R3'),'mech_chaet':('Taladro Arenicola','mediano','M7','F0',56,'R4'),'mech_riftia':('Pinza Glicera','mediano','M3','F5',48,'R5'),'mech_polyn':('Escudo Afrodita','mediano','M1','F4',64,'R6')}
    for source in legacy['worlds']:
        n=source['id']; t=TIMES[n-1]
        unique=[snake(k) for k in source['unique']]; recur=[snake(k) for k in source['recurrent']]
        if n==14: unique=list(robot)
        for oldkey in source['unique']+source['recurrent']:
            key=snake(oldkey)
            if key in robot:
                name,category,motion,fire,size,code=robot[key]; body='robotico'
            else:
                name=entities[oldkey]['name']; body,category,motion,fire,size=body_profile(name); code=None
            if key not in enemy_map:
                enemy_map[key]={'id':key,'familia':name,'tipo':body,'categoria':category,'mundos':{},'movimiento':motion,'disparo':fire,'tamano':[size,size],'puntos':100,'drop':{'moneda_chica':.35,'moneda_grande':.05},'estado':'revisar','blindado':body=='escamoso' or code=='R6','parametros':{'carcasa_abierta_seg':1,'cadena_intervalo_seg':.15}}
                if code: enemy_map[key]['robot_codigo']=code
                if code=='R6': enemy_map[key]['parametros']['carcasa_periodo_seg']=5
            role='unico' if key in unique else 'recurrente'
            enemy_map[key]['mundos'][str(n)]={'rol':role,'sprite_set':f'w{n:02}_enemy_{key}'}
        w={'id':n,'nombre':source['name'],'acto':source['act'],'duracion_hasta_jefe_seg':t,'enemigos_total':COUNTS[n-1],'minijefe_inicio_seg':t/2-30,'minijefe_ventana_seg':60,'alerta_jefe_seg':t-10,'paleta':PALETTES[n-1],'scroll_px_s':60,'cancion_jefe':SONGS[n-1],'musica_etapa':f'w{n:02}_level_instr','musica_jefe':f'w{n:02}_boss_vocal','peligros':HAZARDS[n-1],'minijefe':f'mini_w{n:02}_{MINIS[n-1]}','mini_tipo':MINIS[n-1],'vida_minijefe':MINI_HP[n-1],'unicos':unique,'recurrentes':recur,'jefe_objetivo_seg':TARGETS[n-1],'base_monedas':(n+2)*100 if n<14 else 6200,'jefes':[],'sectores_jefes':[]}
        if n<=7: specs=[(PROFILES[n-1][0],HP[n-1],TARGETS[n-1])]
        elif n==8: specs=[(k,2100,135) for k in ['pollutionCapit','pollutionSpio','pollutionCirrat']]
        elif n<=12: specs=[(['tomo','eulagisca','osedax','alvinella'][n-9],HP[n-1],TARGETS[n-1])]
        elif n==13: specs=[('hadalsovereign',5950,150),('riftia',4000,150)]
        else: specs=[('robot_pinza',2100,90),('robot_torreta',2100,90),('robot_taladro',2100,90),('epitoke',8400,120),('scientist',8400,120),('euniceTitan',12650,180)]
        for archetype,hp,target in specs:
            boss=make_boss(archetype,n,hp,target); bosses.append(boss); w['jefes'].append(boss['id'])
        if n==14:
            w['sectores_jefes']=[{'id':i+1,'jefes':group,'objetivo_seg':target,'base_monedas':money,'texto':line} for i,(group,target,money,line) in enumerate([(w['jefes'][:3],90,1200,'Sala de robóticos'),([w['jefes'][3]],120,1400,'Sala de la epitoca'),([w['jefes'][4]],120,1600,'Sala del científico'),([w['jefes'][5]],180,2000,'Tanque central: Eunice aphroditois')])]
            w['semilla']=seed
            w['laboratorio_organicos']=110;w['laboratorio_roboticos']=140
        base=enemy_map[MINIS[n-1]]
        bosses.append({'id':w['minijefe'],'nombre':f"{base['familia']} gigante",'mundo':n,'arquetipo':'mini_robot' if n==14 else f"mini_{base['movimiento'].lower()}",'tipo':'minijefe','vida':MINI_HP[n-1],'objetivo_seg':50,'minimo_seg':0,'tamano':[128,96],'segmentos':[{'id':'cabeza','hitbox':[0,24,32,48],'debil':True,'mult_dano':2},{'id':'cuerpo','hitbox':[32,0,96,96],'debil':False,'mult_dano':.5}],'fases':[{'desde_pct':100,'hasta_pct':50,'patrones':[base['movimiento'].lower(),base['disparo'].lower()]},{'desde_pct':50,'hasta_pct':0,'patrones':[base['movimiento'].lower(),base['disparo'].lower(),'embestida_telegrafiada']}],'recompensa_extra':0,'objeto_unico':None,'movimiento':base['movimiento'],'disparo':base['disparo'],'drop_item':'arma_mas_baja'})
        worlds.append(w)
    rng=random.Random(seed);rng.seed_value=seed
    for w in worlds: waves[w['id']]=make_waves(w,enemy_map,rng)
    escape={'id':15,'duracion_seg':300,'scroll_px_s':120,'enemigos_total':90,'checkpoint_cada_seg':90,'checkpoints':[0,90,180,270],'recompensa':1000,'sin_tienda':True,'sin_jefe':True,'fondo_transicion':{'desde_seg':210,'hasta_seg':300,'mundo_destino':1},'tramos':[{'inicio_seg':0,'fin_seg':90,'enemigos':30,'peligros':['compuertas','laseres']},{'inicio_seg':90,'fin_seg':210,'enemigos':40,'peligros':['escombros','corrientes']},{'inicio_seg':210,'fin_seg':300,'enemigos':20,'peligros':[]}],'eventos':[]}
    for section,amounts in zip(escape['tramos'],[[10,10,10],[10,10,10,10],[20]]):
        for i,count in enumerate(amounts):
            key='mech_syll' if count==20 else ['mech_nereis','mech_syll','syll','spio'][i%4]
            escape['eventos'].append({'t':section['inicio_seg']+10+i*(section['fin_seg']-section['inicio_seg']-20)/len(amounts),'tipo':'oleada','enemigo':key,'cantidad':count,'formacion':FORMATIONS[i%len(FORMATIONS)],'y':100+i*40,'portadora':False,'separacion_px':32,'separacion_seg':.3})
        for hazard in section['peligros']:
            for t in range(int(section['inicio_seg'])+4,int(section['fin_seg'])-3,12): escape['eventos'].append({'t':t,'tipo':'peligro','id':hazard,'duracion_seg':3,'y':168})
    escape['eventos'].sort(key=lambda e:e['t'])
    return {'worlds':worlds,'enemies':list(enemy_map.values()),'bosses':bosses,'combat':combat_data(),'waves':waves,'escape':escape}


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--seed',type=int,default=20261101);args=parser.parse_args()
    campaign=build_campaign(args.seed)
    (ROOT/'data/waves').mkdir(exist_ok=True)
    for name,data in campaign.items():
        if name=='waves':
            for n,events in data.items(): (ROOT/f'data/waves/world_{n:02}.json').write_text(json.dumps(events,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
        else: (ROOT/f'data/{name}.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print('Generated 14 stages, 36 bosses/minibosses and the 300 s escape.')


if __name__=='__main__': main()
