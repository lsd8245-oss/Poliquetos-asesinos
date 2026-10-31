const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {spawnSync}=require('node:child_process');
const root=path.resolve(__dirname,'..');
const read=p=>JSON.parse(fs.readFileSync(path.join(root,p),'utf8'));

test('v2 inventory preserves all legacy types, world roles and separate boss participants',()=>{
 const saved=read('data/legacy_inventory.json');
 const {inventory}=require('../scripts/inventory-legacy.cjs');
 assert.deepEqual(saved,inventory(root),'inventory is stale');
 assert.equal(saved.worlds.length,14);
 assert.equal(saved.entities.length,119);
 const byId=new Map(saved.entities.map(e=>[e.id,e]));
 const uniques=[
 'hydroides euphrosine fabric pision lacy',
 'arenicola magelona sthenelais sacco goniada',
 'dodeca oenone arabella spha histrio',
 'spirorbis myxicola spinther trocho cteno',
 'spirobranchus sabellastarte eulepeth acoet pholoe',
 'glycera diopatra chaetopterus sabellaria pectinaria',
 'aricidea terebellides questa fauvel protod',
 'ophelia cossura pilarg lumbrineris owenia',
 'pontod lopado typhlo poeo iospil',
 'flabegraviera aphelochaeta mald perkinsiana amphar',
 'hesiocaeca nautil chryso brada bathykurila',
 'riftia paralvinella branchinotogluma amphisamytha hesiolyra',
 'swima aphro scali stern macellicephaloides',
 'mechNereis mechPolyn mechRiftia mechChaet mechSyll mechSabel'];
 const recurrent=[
 'syll phyll','spio nepht glycer','syll spio phyll serp hesio',
 'syll phyll cirrat','syll phyll hesio','syll nepht hesio',
 'spio nepht glycer','glycer dorville','syllStolon alciop',
 'spio serp alciop','cirrat ophryotrocha','serp cirrat dorville',
 'nepht glycer dorville alciop cirrat'];
 const bosses=[
 'nereis','capit','polyn','tere','hermo','leafqueen','orbin',
 'capit pollutionSpio pollutionCirrat','tomo','eulagisca','osedax','alvinella',
 'hadalsovereign riftia','mechNereis mechPolyn mechOrbin mechTere epitoke scientist euniceTitan'];
 for(const [i,w] of saved.worlds.entries()){
  assert.deepEqual(w.unique,uniques[i].split(' '));
  if(i<13)assert.deepEqual(w.recurrent,recurrent[i].split(' '));
  assert.deepEqual(w.bosses.map(b=>b.id),bosses[i].split(' '));
  for(const role of ['unique','recurrent'])for(const id of w[role]){
   assert.ok(byId.get(id)?.appearances.some(a=>a.world===w.id&&a.role===role),`${id} role in ${w.id}`);
  }
  for(const b of w.bosses){
   assert.ok(byId.has(b.type));
   assert.equal(b.sprite.key,b.id);
   assert.equal(b.sprite.renderer,'getBossSprite');
  }
 }
 assert.equal(saved.worlds[7].bosses.length,3);
 assert.equal(saved.worlds[12].bosses.length,2);
 assert.equal(saved.worlds[13].bosses.length,7);
 for(const e of saved.entities){assert.ok(e.stats.baseHp>0);assert.equal(e.sprite.format,'canvas_procedural');}
});

test('v2 inventory generation is deterministic and does not alter either edition',()=>{
 const {inventory}=require('../scripts/inventory-legacy.cjs');
 const files=['versiones/poliquetos-normal.html','versiones/poliquetos-pruebas.html'];
 const before=files.map(f=>fs.readFileSync(path.join(root,f)));
 assert.deepEqual(inventory(root),inventory(root));
 files.forEach((f,i)=>assert.deepEqual(fs.readFileSync(path.join(root,f)),before[i]));
});

test('v2 data contracts validate fixtures and reject invalid game data',()=>{
 const result=spawnSync('python3',['scripts/validate-v2-data.py','--self-test'],{cwd:root,encoding:'utf8'});
 assert.equal(result.status,0,result.stdout+result.stderr);
 assert.match(result.stdout,/contracts verified/);
});
