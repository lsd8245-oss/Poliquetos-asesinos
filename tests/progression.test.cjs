const {test}=require('node:test'),assert=require('node:assert/strict');const {engine}=require('./helpers/game.cjs');
test('oceanographic tools are sold only in their PDF act',()=>{
 const g=engine(),gates={sonar:1,draga:1,net:1,niskin:2,box:2,ctd:2,multi:3,rov:3,lander:3,photon:4};
 for(const [level,act]of [[1,1],[41,2],[81,3],[131,4]]){
  const {r,p,sockets}=g.room(level);g.api.debug.toUpgrade(r);p.credits=99999;
  for(const [id,gate]of Object.entries(gates)){const row=g.api.debug.compactShopFor(r,p).catalog.find(r=>r.id===id);assert.equal(row.unlockAct,gate,id);assert.equal(row.available,act>=gate,id);if(act<gate){const before=p.credits;g.api.parseClient(sockets[0],{t:'shopBuy',id});assert.equal(p.credits,before);assert.ok(!p.ownedEquipment.includes(id));}}
 }
});
test('cosmetic purchase charges the authoritative price once and survives save/restore',()=>{
 const g=engine(),{r,p,sockets}=g.room(2);g.api.debug.toUpgrade(r);p.credits=900;
 const row=g.api.debug.compactShopFor(r,p).catalog.find(r=>r.kind==='skin'&&r.id==='skin:skin-07');assert.ok(row,'shop has purchasable cosmetic skins');
 g.api.parseClient(sockets[0],{t:'shopBuy',id:row.id,price:0,credits:999999});assert.equal(p.credits,900-row.price);assert.ok(p.ownedSkins.includes('skin-07'));
 const after=p.credits;g.api.parseClient(sockets[0],{t:'shopBuy',id:row.id});assert.equal(p.credits,after);
 p.appearance.id='skin-07';const save=g.api.debug.makeCheckpoint(r),next=g.room(1);g.api.debug.restoreCheckpoint(next.r,save);assert.ok(next.p.ownedSkins.includes('skin-07'));assert.equal(next.p.appearance.id,'skin-07');assert.equal(next.p.credits,after);
});
test('failed or out-of-phase purchases never change credit or ownership',()=>{
 const g=engine(),{r,p,sockets}=g.room(1);p.credits=500;g.api.parseClient(sockets[0],{t:'shopBuy',id:'skin:skin-07'});assert.equal(p.credits,500);
 g.api.debug.toUpgrade(r);p.credits=0;g.api.parseClient(sockets[0],{t:'shopBuy',id:'skin:skin-07'});assert.equal(p.credits,0);assert.ok(!p.ownedSkins?.includes('skin-07'));
});
test('rewarding the same sector twice never manufactures credits',()=>{const g=engine(),{r,p}=g.room(45);g.api.debug.compactAwardSector(r);const credit=p.credits;g.api.debug.compactAwardSector(r);assert.equal(p.credits,credit);assert.ok(credit>=100)});
test('rest appearance cannot equip an unowned paid or boss skin',()=>{const g=engine(),{r,p,sockets}=g.room(1);g.api.debug.toUpgrade(r);g.api.parseClient(sockets[0],{t:'appearance',appearance:{id:'skin-26'}});assert.equal(p.appearance.id,'base')});
