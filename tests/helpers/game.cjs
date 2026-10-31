const {readFileSync,readdirSync}=require('node:fs');const {join}=require('node:path');const vm=require('node:vm');
const root=join(__dirname,'../..');const file=readdirSync(root).find(n=>n.endsWith('.html'));
function source(){return readFileSync(join(root,file),'utf8')}
function engine({sandbox=false}={}){
 const html=source().replace('const POLIGAMES_SANDBOX=false;','const POLIGAMES_SANDBOX='+sandbox+';'),script=html.match(/<script>([\s\S]*?)<\/script>/)[1];
 const marker='return {rooms,newRoom,attach,parseClient,tickRoom,detach};';
 const exposed=script.replace(marker,`return {rooms,newRoom,attach,parseClient,tickRoom,detach,debug:{startGame,nextLevel,spawnEnemy,hurtEnemy,makeCheckpoint,restoreCheckpoint,toUpgrade,endGame,compactShopFor,compactAwardSector,TYPES,sendState,phaseAttack}};`);
 const messages=[],vmContext={console,setTimeout,clearTimeout,window:{PA4LocalMessage:m=>messages.push(m)}};
 vm.runInNewContext(exposed+';globalThis.result={api:PA4Engine,worlds:CAMPAIGN_WORLDS,spec:campaignLevelSpec,act:campaignAct,total:TOTAL_CAMPAIGN_LEVELS,migrate:migrateCampaignCheckpoint};',vmContext,{timeout:15000});
 const game=vmContext.result;game.messages=messages;
 game.room=(level=1,solo=true)=>{
  const r=game.api.newRoom(solo);r.code='TEST';const sockets=[];
  for(let i=0;i<(solo?1:2);i++){const ws={local:true,closed:false};game.api.attach(ws,r,'Piloto '+(i+1));sockets.push(ws)}
  r.startLevel=level;game.api.debug.startGame(r);return {r,sockets,p:r.members.get(1)};
 };
 return game;
}
module.exports={engine,source,root,file};
