const {test, before, after}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync,readdirSync}=require('node:fs');
const {join}=require('node:path');
const {createServer}=require('node:http');
const {chromium}=require('playwright');
const root=join(__dirname,'..');
const filename=readdirSync(root).find(n=>n.endsWith('.html'));
// Expose internals only in the served test copy; the downloadable game has no test API.
const bridge=`window.gameTest={get paintShip(){return paintShip},get background(){return background},get audio(){return audio},get musicBus(){return musicBus},get synthBus(){return synthBus},get app(){return app},get track(){return currentTrack},get acoustics(){return typeof oceanAcoustics==='undefined'?null:oceanAcoustics},get createAcoustics(){return typeof createOceanAcoustics==='function'?createOceanAcoustics:null},get profile(){return typeof oceanMusicProfile==='function'?oceanMusicProfile:null}};`;
let browser,server,url;
before(async()=>{
 const html=readFileSync(join(root,filename),'utf8');
 const marker='installUI();initEquipmentUI();initArmory();initVocals();initAudioChecks();';
 assert.ok(html.includes(marker),'test bridge must be inserted inside the existing game closure');
 server=createServer((req,res)=>{res.setHeader('Content-Type','text/html; charset=utf-8');res.end(html.replace(marker,bridge+marker));});
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 url=`http://127.0.0.1:${server.address().port}/`;
 browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',headless:true,args:['--no-sandbox']});
});
after(async()=>{await browser?.close();await new Promise(resolve=>server?.close(resolve));});

test('ocean acoustics create a finite stereo decay, with no tail when the wet path is muted',async()=>{
 const p=await browser.newPage();try{
 await p.goto(url);
 assert.equal(await p.evaluate(()=>typeof gameTest.createAcoustics),'function','the ocean music processor is available');
 const result=await p.evaluate(async()=>{
  const render=async(wet)=>{
   const c=new OfflineAudioContext(2,44100*2,44100),input=c.createGain();
   const graph=gameTest.createAcoustics(c,input,c.destination);graph.wet.gain.value=wet;
   const impulse=c.createBuffer(1,1,44100);impulse.getChannelData(0)[0]=.5;
   const src=c.createBufferSource();src.buffer=impulse;src.connect(input);src.start(0);
   const out=await c.startRendering();
   let tail=0,stereoDifference=0,peak=0;
   const left=out.getChannelData(0),right=out.getChannelData(1);
   for(let i=0;i<left.length;i++){peak=Math.max(peak,Math.abs(left[i]),Math.abs(right[i]));if(i>4410){tail+=left[i]**2+right[i]**2;stereoDifference+=Math.abs(left[i]-right[i]);}}
   return {tail,stereoDifference,peak,finite:[...left,...right].every(Number.isFinite)};
  };return {wet:await render(.25),dry:await render(0)};
 });
 assert.ok(result.wet.tail>1e-7,'reverb should outlast the dry impulse');
 assert.ok(result.wet.stereoDifference>.001,'left and right decay should differ');
 assert.ok(result.wet.peak<1&&result.wet.finite,'output must remain finite and below clipping');
 assert.ok(result.dry.tail<1e-10,'muting the wet path removes the reverb tail');
 }finally{await p.close()}
});

test('battle mix keeps attacks clearer than the exploration mix',async()=>{
 const p=await browser.newPage();try{await p.goto(url);
 assert.equal(await p.evaluate(()=>typeof gameTest.profile),'function');
 const result=await p.evaluate(()=>({explore:gameTest.profile(false,.5),battle:gameTest.profile(true,1)}));
 assert.ok(result.battle.wet<result.explore.wet,'battle instruments need less reverb for clear attacks');
 assert.ok(result.battle.cutoff>result.explore.cutoff,'battle mix should preserve brighter transients');
 }finally{await p.close()}
});

test('offline game renders, pauses, mutes the complete music mix, and restores its checkpoint',async()=>{
 const p=await browser.newPage({viewport:{width:1280,height:800}});const errors=[];const external=[];
 p.on('pageerror',e=>errors.push(e.message));
 await p.route('**/*',route=>{if(route.request().url().startsWith(url))return route.continue();external.push(route.request().url());return route.abort();});
 try{
 await p.goto(url);await p.locator('#solo').click();
 await p.waitForFunction(()=>gameTest.audio?.state==='running'&&gameTest.acoustics);
 // Listen after the music master so pause/mute covers both dry notes and reverb.
 await p.evaluate(()=>{const a=gameTest.audio.createAnalyser();a.fftSize=2048;gameTest.musicBus.connect(a);window.musicRms=()=>{const d=new Float32Array(a.fftSize);a.getFloatTimeDomainData(d);return Math.sqrt(d.reduce((n,x)=>n+x*x,0)/d.length)};});
 await p.waitForFunction(()=>musicRms()>.0001);
 await p.locator('#pauseBtn').click();await p.locator('#paused').waitFor({state:'visible'});
 await p.waitForFunction(()=>musicRms()<.00001);
 await p.locator('#resumeBtn').click();await p.waitForFunction(()=>musicRms()>.0001);
 await p.evaluate(()=>{gameTest.app.musicVol=0});await p.waitForFunction(()=>musicRms()<.00001);
 assert.equal(await p.evaluate(()=>gameTest.audio.state),'running','muting music should leave FX available');
 await p.evaluate(()=>{gameTest.app.musicVol=.6});await p.waitForFunction(()=>musicRms()>.0001);
 await p.reload();await p.locator('#continueBtn').click();await p.locator('#pauseBtn').waitFor({state:'visible'});
 assert.equal(await p.evaluate(()=>JSON.parse(localStorage.getItem('pa-gba-checkpoint-v1')).level),1);
 assert.deepEqual(external,[],'single-player graphics and sound need no network assets');assert.deepEqual(errors,[]);
 }finally{await p.close()}
});


test('submarine lighting preserves invulnerability transparency',async()=>{
 const p=await browser.newPage();try{await p.goto(url);
 const values=await p.evaluate(()=>{
  const c=document.createElement('canvas');c.width=128;c.height=96;const g=c.getContext('2d');
  g.translate(64,48);g.globalAlpha=.25;gameTest.paintShip(g,gameTest.app.appearance,0);
  return {hullAlpha:g.getImageData(66,48,1,1).data[3],callerAlpha:g.globalAlpha};
 });
 assert.ok(values.hullAlpha<=65&&values.hullAlpha>0,'lighting must not make an invulnerable hull opaque');
 assert.equal(values.callerAlpha,.25);
 }finally{await p.close()}
});
