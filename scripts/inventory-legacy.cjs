// Read-only snapshot of the existing engine. Never used by the shipped game.
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const {createHash}=require('node:crypto');
const CANONICAL='poliquetos_asesinos_8_edicion_sonora (18).html';

function inventory(root=path.resolve(__dirname,'..')){
 const html=fs.readFileSync(path.join(root,CANONICAL),'utf8');
 const script=html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
 const marker='return {rooms,newRoom,attach,parseClient,tickRoom,detach};';
 if(!script?.includes(marker))throw new Error('Legacy engine export not found; review the extractor.');
 const context={console,setTimeout,clearTimeout,window:{PA4LocalMessage(){}}};
 vm.runInNewContext(script.replace(marker,'return {inventoryTypes:TYPES};')+
  ';globalThis.snapshot={types:PA4Engine.inventoryTypes,worlds:CAMPAIGN_WORLDS};',context,{timeout:15000});
 // Cross-realm values become ordinary serializable records here.
 const {types,worlds}=JSON.parse(JSON.stringify(context.snapshot));
 const sprite=(key,boss=false)=>({format:'canvas_procedural',key,renderer:boss?'getBossSprite':'getWormSprite',png:null});
 const entities=Object.entries(types).map(([id,t])=>({
  id,name:t[0],stats:{color:t[1],radius:t[2],baseHp:t[3],baseSpeed:t[4],attack:t[5]},
  appearances:worlds.flatMap(w=>['unique','recurrent'].filter(role=>w[role].includes(id)).map(role=>({world:w.world,role}))),
  bossAppearances:worlds.flatMap(w=>w.bossRoster.filter(b=>b.type===id).map(b=>({world:w.world,id:b.bossId,name:b.name}))),
  sprite:sprite(id)
 }));
 return {
  version:1,
  source:{file:CANONICAL,sha256:createHash('sha256').update(html).digest('hex'),campaign:8,
   statsNote:'Base TYPES values only; actual HP, speed, radius and contact damage are scaled by spawnEnemy and its wrappers. Not v2 balance.',
   spritesNote:'Runtime Canvas atlases, not external PNG assets. Renderer keys are selectors, not file paths.'},
  worlds:worlds.map(w=>({id:w.world,act:w.act,name:w.name,unique:w.unique,recurrent:w.recurrent,
   legacyStageCount:w.levels,bosses:w.bossRoster.map(b=>({id:b.bossId,type:b.type,name:b.name,sprite:sprite(b.bossId,true)}))})),
  entities
 };
}
if(require.main===module){
 const root=path.resolve(__dirname,'..');
 fs.mkdirSync(path.join(root,'data'),{recursive:true});
 const result=inventory(root);
 fs.writeFileSync(path.join(root,'data/legacy_inventory.json'),JSON.stringify(result,null,2)+'\n');
 console.log(`Inventoried ${result.entities.length} legacy types across ${result.worlds.length} worlds.`);
}
module.exports={inventory};
