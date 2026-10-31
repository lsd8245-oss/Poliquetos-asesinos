const {test,before,after}=require('node:test'),assert=require('node:assert/strict'),{launch}=require('./helpers/browser.cjs');let env;
before(async()=>{env=await launch()});after(async()=>env?.close());
test('shipyard opens from rest, equips a skin, and returns to the same paused sector',async()=>{
 const p=await env.browser.newPage();const errors=[];p.on('pageerror',e=>errors.push(e.message));try{
 await p.goto(env.url);await p.locator('#solo').click();
 await p.evaluate(()=>{const g=poliTest;g.engine.debug.toUpgrade(g.app.room)});
 await p.locator('#restHarbor').click({timeout:3000});await p.locator('#harbor').waitFor({state:'visible'});
 await p.locator('#shipBody').evaluate(e=>{e.value='#123456';e.dispatchEvent(new Event('input'))});await p.locator('#shipApply').click();assert.equal(await p.evaluate(()=>poliTest.app.room.members.get(1).appearance.body),'#123456');await p.locator('#harborBack').click();await p.locator('#upgrades').waitFor({state:'visible'});
 const state=await p.evaluate(()=>({phase:poliTest.app.room.phase,level:poliTest.app.room.level}));assert.equal(state.phase,'upgrade');assert.equal(state.level,1);assert.deepEqual(errors,[]);
 }finally{await p.close()}
});
test('equipment shortcuts reject conflicts and persist across reload',async()=>{
 const p=await env.browser.newPage();try{await p.goto(env.url);await p.locator('#gbaOpenOptions').click();
 await p.locator('#gearKey-draga').selectOption('y',{timeout:3000});
 const result=await p.evaluate(()=>({key:poliTest.gearKey('draga'),reserved:poliTest.setGearKey('draga','w'),duplicate:poliTest.setGearKey('net','y')}));assert.equal(result.key,'y');assert.equal(result.reserved,false);assert.equal(result.duplicate,false);
 await p.reload();assert.equal(await p.evaluate(()=>poliTest.gearKey('draga')),'y');
 }finally{await p.close()}
});
test('death menu retry continues the same sector',async()=>{
 const p=await env.browser.newPage();try{await p.goto(env.url);await p.locator('#solo').click();
 await p.evaluate(()=>{const g=poliTest,r=g.app.room;r.startLevel=7;g.engine.debug.startGame(r);g.engine.debug.endGame(r,false);g.renderEnd({win:false,level:7,kills:0,score:0,time:0})});
 await p.locator('#again').click();await p.waitForFunction(()=>poliTest.app.phase==='playing');assert.equal(await p.evaluate(()=>poliTest.app.room.level),7);
 }finally{await p.close()}
});
test('wider playfield retains controls on screen at desktop and landscape-mobile sizes',async()=>{
 const p=await env.browser.newPage();try{await p.goto(env.url);
 for(const size of [{width:1440,height:900},{width:844,height:390}]){
  await p.setViewportSize(size);const boxes=await p.evaluate(({width,height})=>poliTest.layout(width,height),size);assert.ok(boxes.game.width/size.width>(size.height<450?.70:.85));assert.ok(boxes.game.width*boxes.game.height/(size.width*size.height)>.67);assert.ok(boxes.game.height/size.height>.7);assert.ok(boxes.consumables.left>=0);assert.ok(boxes.consumables.left+boxes.consumables.width<=size.width);
 }
 await p.locator('#solo').click();assert.notEqual(await p.locator('[data-act=dash]>svg').evaluate(e=>getComputedStyle(e).display),'none');
 }finally{await p.close()}
});
test('old destination unlocks migrate once without losing access to moved habitats',async()=>{
 const p=await env.browser.newPage();try{await p.goto(env.url);await p.evaluate(()=>{localStorage.clear();localStorage.setItem('pa-gba-unlocked-v1','9');localStorage.setItem('pa-gba-progress-v1','1')});await p.reload();assert.equal(await p.evaluate(()=>poliTest.app.unlockedWorld),11);await p.reload();assert.equal(await p.evaluate(()=>poliTest.app.unlockedWorld),11);}finally{await p.close()}
});
test('a permanent paid skin remains owned in a new expedition after reloading',async()=>{
 const p=await env.browser.newPage();try{await p.goto(env.url);await p.locator('#solo').click();await p.evaluate(()=>{const g=poliTest,r=g.app.room;g.engine.debug.toUpgrade(r);r.members.get(1).credits=900;g.engine.debug.sendChoices(r)});await p.locator('#gbaTreasure').click();await p.locator('#bit32Tab-skins').click();await p.locator('[data-shop-id="skin:skin-07"]').click();assert.ok(await p.evaluate(()=>poliTest.app.ownedSkins.has('skin-07')));
 await p.reload();await p.locator('#solo').click();await p.evaluate(()=>{const g=poliTest;g.engine.debug.toUpgrade(g.app.room)});const owned=await p.evaluate(()=>poliTest.app.compactShop.catalog.find(r=>r.id==='skin:skin-07').owned);assert.equal(owned,true);
 }finally{await p.close()}
});
test('audio options expose only music and effect switches with their volume controls',async()=>{
 const p=await env.browser.newPage();try{await p.goto(env.url);await p.locator('#gbaOpenOptions').click();await p.locator('#audioSettings').evaluate(e=>e.open=true);assert.equal(await p.locator('#audioSettings button:visible').count(),2);assert.equal(await p.locator('#audioSettings input[type=range]:visible').count(),2);}finally{await p.close()}
});
