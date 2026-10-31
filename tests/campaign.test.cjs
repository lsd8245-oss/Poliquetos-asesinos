const {test}=require('node:test');const assert=require('node:assert/strict');const {engine}=require('./helpers/game.cjs');
const counts=[[7,7,7,10,10,10,13,13,13],[13,13,13,13,13,15,15,15,15],...[0,0,0].map(()=>Array(9).fill(15)),...[0,0].map(()=>[15,15,15,15,18,18,18,18,18]),...[0,0].map(()=>Array(9).fill(18)),...[0,0].map(()=>[20,20,20,20,20,25,25,25,25]),[25,25,25,25,25,30,30,30,30],[30,30,30,30,30,30,35,35,35],[10,13,16,20,23,23,23,25,25]];
test('PDF campaign has14 worlds and144 unique sectors with correct act boundaries',()=>{
 const g=engine();assert.equal(g.worlds.length,14);assert.equal(g.total,144);
 const all=Array.from({length:144},(_,i)=>g.spec(i+1));assert.equal(new Set(all.map(s=>s.world+':'+s.stage)).size,144);
 for(const [level,act]of [[1,1],[40,1],[41,2],[80,2],[81,3],[130,3],[131,4],[144,4]])assert.equal(g.act(level),act);
 assert.equal(g.spec(144).encounter,'escape');assert.equal(g.spec(143).bossId,'euniceTitan');
});
test('all normal waves match PDF counts equally in solo and coop; every type can spawn',()=>{
 const g=engine();for(let w=0;w<14;w++)for(let stage=0;stage<9;stage++){
  const level=w*10+stage+1;for(const solo of [true,false]){const {r}=g.room(level,solo);assert.equal(r.goal,counts[w][stage],`world${w+1} stage${stage+1} solo${solo}`)}
  for(const pool of g.spec(level).pools)for(const id of pool)assert.ok(g.api.debug.TYPES[id],`missing type ${id}`);
 }
});
test('boss stages have no ordinary waves, pollution trio and hadal duo are actual separate bosses',()=>{
 const g=engine();for(let world=1;world<=13;world++){
  const {r,p}=g.room(world*10);p.inv=999;r.spawnCd=0;assert.equal(r.goal,0);
  for(let i=0;i<200;i++)g.api.tickRoom(r);
  assert.ok(r.enemies.length>0);assert.ok(r.enemies.every(e=>e.boss),`world${world} spawned ordinary enemies`);
  if(world===8)assert.equal(r.enemies.length,3);if(world===13)assert.equal(r.enemies.length,2);
 }
});
test('old campaign7 saves migrate by habitat and preserve bought equipment and credits',()=>{
 const g=engine();for(const [old,expected]of [[41,61],[51,41],[61,71],[71,21],[81,101],[91,51],[121,81],[131,111],[141,91],[151,131],[158,140],[161,141],[162,142],[163,143],[164,144],[165,144]]){
  const c=g.migrate({v:1,campaign:7,level:old,stats:{hp:100},economy:{version:'gbav1',credits:250,ownedEquipment:['sonar','net'],rewarded:[old],highestCleared:old}});
  assert.equal(c.level,expected,`old level ${old}`);assert.equal(c.campaign,8);assert.equal(c.economy.credits,250);assert.equal(c.economy.rewarded[0],expected);
 }
});
test('last-sector retry restores each pilots purchases instead of resetting the expedition',()=>{
 const g=engine();for(const solo of [true,false]){
  const {r,sockets,p}=g.room(24,solo);p.credits=333;p.ownedEquipment.push('net');p.upgradeCount.damage=2;p.damage=28;
  g.api.debug.nextLevel(r);const hp=r.members.get(1).hp;r.members.get(1).credits=0;g.api.debug.endGame(r,false);
  g.api.parseClient(sockets[0],{t:'retry'});assert.equal(r.level,25);assert.equal(r.phase,'playing');assert.equal(r.members.get(1).credits,333);assert.equal(r.members.get(1).hp,hp);assert.ok(r.members.get(1).ownedEquipment.includes('net'));assert.equal(r.members.get(1).upgradeCount.damage,2);
 }
});
test('one escape is endless for180 active seconds, freezes on pause, and finishes with enemies alive',()=>{
 const g=engine(),{r,p,sockets}=g.room(144);p.inv=999;p.maxHp=p.hp=100000;
 for(let i=0;i<60*30;i++)g.api.tickRoom(r);assert.equal(r.phase,'playing');assert.ok(r.enemies.length>0);assert.ok(r.escapeRemaining>149&&r.escapeRemaining<151);
 g.api.parseClient(sockets[0],{t:'pause',paused:true});const remaining=r.escapeRemaining;for(let i=0;i<600;i++)g.api.tickRoom(r);assert.equal(r.escapeRemaining,remaining);
 g.api.parseClient(sockets[0],{t:'pause',paused:false});for(let i=0;i<60*149;i++)g.api.tickRoom(r);assert.equal(r.phase,'playing');for(let i=0;i<61;i++)g.api.tickRoom(r);assert.ok(r.phase==='won'||r.cinematic?.kind==='finale');
});
test('Eunice is anchored and mechanical gauntlet requires four distinct bosses',()=>{
 const g=engine(),{r,p}=g.room(143);p.inv=999;for(let i=0;i<150;i++)g.api.tickRoom(r);const e=r.enemies.find(e=>e.bossId==='euniceTitan');assert.ok(e);const pos=[e.x,e.y];for(let i=0;i<360;i++)g.api.tickRoom(r);assert.deepEqual([e.x,e.y],pos);assert.equal(e.speed,0);
 const gauntlet=g.room(140);assert.equal(gauntlet.r.labBossTotal,4);assert.equal(g.spec(140).bossRoster.length,4);
});
test('fixed waves complete after their exact budget, including a Syllid without extra offspring',()=>{
 const g=engine(),{r,p}=g.room(1);p.inv=999;const first=g.api.debug.spawnEnemy(r,'syll',false,{x:600,y:300});r.spawned=1;g.api.debug.hurtEnemy(r,first,1e9,p);
 for(let i=0;i<6000&&r.phase==='playing';i++){g.api.tickRoom(r);for(const e of [...r.enemies])g.api.debug.hurtEnemy(r,e,1e9,p);}
 assert.equal(r.phase,'upgrade');assert.equal(r.spawned,7);assert.equal(r.kills,7);
});
test('all mechanical bosses must die, and grouped encounters wait for their final member',()=>{
 const g=engine();for(const [level,total]of [[80,3],[130,2],[140,4]]){
  const {r,p}=g.room(level);p.inv=999;const types=new Set();let first=true;
  for(let i=0;i<1500&&r.phase==='playing';i++){
   g.api.tickRoom(r);const list=[...r.enemies].filter(e=>e.boss);
   if(first&&list.length){first=false;const e=list[0];e.hp=e.maxHp=1;e.phaseCount=1;e.phaseLock=0;e.guard=0;types.add(e.type);g.api.debug.hurtEnemy(r,e,1e9,p);assert.equal(r.phase,'playing');continue;}
   for(const e of list){e.hp=e.maxHp=1;e.phaseCount=1;e.phaseLock=0;e.guard=0;types.add(e.type);g.api.debug.hurtEnemy(r,e,1e9,p);}
  }
  assert.equal(types.size,total,'distinct bosses in sector'+level);assert.equal(r.labBossDefeated,total);assert.equal(r.phase,'upgrade');
 }
});
test('mechanical quartet bosses use telegraphed laboratory laser attacks',()=>{
 const g=engine(),{r,p}=g.room(140);for(const type of ['mechNereis','mechPolyn','mechOrbin','mechTere']){
  r.enemies=[];r.bossHazards=[];r.enemyFireEvents=[];const e=g.api.debug.spawnEnemy(r,type,true,{x:680,y:310});e.bossId=type;e.phaseLock=0;e.adaptiveRecovery=0;e.a=Math.PI;
  g.api.debug.phaseAttack(r,e,p);assert.ok(r.enemyFireEvents.some(event=>event.kind==='laser'),type+' should signal its laser attack');
 }
});
test('reordered-world migration preserves every already rewarded sector on restore',()=>{
 const g=engine(),old=g.room(61),save=g.api.debug.makeCheckpoint(old.r);save.campaign=7;save.economy.highestCleared=60;save.economy.rewarded=Array.from({length:60},(_,i)=>i+1);
 const migrated=g.migrate(save);assert.equal(migrated.economy.highestCleared,70);
 const current=g.room(1);g.api.debug.restoreCheckpoint(current.r,migrated);assert.equal(current.r.economyRewarded.size,60);for(let i=61;i<=70;i++)assert.ok(current.r.economyRewarded.has(i));
});
