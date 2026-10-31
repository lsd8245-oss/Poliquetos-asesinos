const {createServer}=require('node:http');const {chromium}=require('playwright');const {source}=require('./game.cjs');
async function launch(){
 let html=source().replace('return {rooms,newRoom,attach,parseClient,tickRoom,detach};','return {rooms,newRoom,attach,parseClient,tickRoom,detach,debug:{toUpgrade,sendChoices,sendState,endGame,startGame,spawnEnemy,hurtEnemy}};');
 const bridge=`window.poliTest={app,engine:PA4Engine,get setGearKey(){return typeof setGearKey==='function'?setGearKey:null},get gearKey(){return typeof gearKey==='function'?gearKey:null},background,canvas,ctx,get layout(){return modernLayoutFor},renderEnd};`;
 const marker='installUI();initEquipmentUI();initArmory();initVocals();initAudioChecks();';html=html.replace(marker,bridge+marker);
 const server=createServer((q,r)=>{r.setHeader('Content-Type','text/html; charset=utf-8');r.end(html)});await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const url=`http://127.0.0.1:${server.address().port}/`,browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',headless:true,args:['--no-sandbox']});
 return {browser,url,async close(){await browser.close();await new Promise(r=>server.close(r))}};
}
module.exports={launch};
