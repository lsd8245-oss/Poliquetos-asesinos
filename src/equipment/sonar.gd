extends RefCounted
## Informational only. Never writes enemies, hazards, CTD flags or save profiles.
var cooldown=0.0
var remaining=0.0
var origin=Vector2.ZERO
var config:Dictionary
func _init(values:Dictionary):config=values.duplicate(true)
func reset():
	cooldown=0.0;remaining=0.0
func advance(effective_dt:float):
	cooldown=maxf(0,cooldown-maxf(0,effective_dt))
	remaining=maxf(0,remaining-maxf(0,effective_dt))
func activate(profile:Dictionary,pos:Vector2)->bool:
	if not profile.get("equipment",{}).get("sonar",false) or cooldown>0:return false
	origin=pos
	cooldown=float(config.cooldown_seconds)
	remaining=float(config.reveal_seconds)
	return true
func reveals(pos:Vector2)->bool:
	return remaining>0 and pos.distance_to(origin)<=float(config.range_px)
func age()->float:return maxf(0,float(config.reveal_seconds)-remaining)
func status()->String:return "%02d s"%ceili(cooldown) if cooldown>0 else "LISTO"
func draw_pulse(canvas:CanvasItem,assets,reduced:bool):
	if remaining<=0:return
	var phase=age()/float(config.sweep_seconds)
	if phase>1:return
	var radius=maxf(2,float(config.range_px)*phase)
	assets.sprite(canvas,"w01_fx_bubble_burst",Rect2(origin-Vector2.ONE*radius,Vector2.ONE*radius*2),age(),Color(0.5,0.95,1,(0.18 if reduced else 0.4)*(1-phase*0.6)))
