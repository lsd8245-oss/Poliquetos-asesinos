extends SceneTree
const Main=preload("res://src/core/main.gd")
const Shop=preload("res://src/shop/shop.gd")
const Save=preload("res://src/save/saves.gd")
var failures=[]
var original_files={}
func snapshot_dir(path:String)->Dictionary:
	var result={}
	var dir=DirAccess.open(path)
	if dir==null:return result
	for name in dir.get_files():result[path.path_join(name)]=FileAccess.get_file_as_bytes(path.path_join(name))
	for name in dir.get_directories():result.merge(snapshot_dir(path.path_join(name)))
	return result
func restore_files():
	for path in snapshot_dir("user://normal"):
		if not original_files.has(path):DirAccess.remove_absolute(path)
	for path in original_files:
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var f=FileAccess.open(path,FileAccess.WRITE);f.store_buffer(original_files[path]);f.close()
func check(ok:bool,label:String):
	if not ok:failures.append(label)
func write(path:String,text:String):
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(text);f.close()
func remove_current(slot:int):
	for suffix in ["",".bak"]:
		if FileAccess.file_exists(Save.file_path(slot)+suffix):DirAccess.remove_absolute(Save.file_path(slot)+suffix)
func _initialize():call_deferred("run")
func run():
	original_files=snapshot_dir("user://normal")
	var ui=Main.new();root.add_child(ui);await process_frame;ui.set_process(false)
	for pair in [[3,2],[6,4]]:
		remove_current(3)
		var old=Shop.create_profile();old.version=2;old.world=pair[0];old.resume="playing";old.credits=430
		var raw=Save._encode(old);write(Save.legacy_file_path(3),raw)
		ui.slot_mode="load";ui._activate("slot:3")
		check(ui.screen=="migration" and ui.pending_migration_notice.contains(str(pair[0])),"removed world notice before starting")
		ui._activate("migration_cancel")
		check(ui.screen=="slots" and not FileAccess.file_exists(Save.file_path(3)),"cancel never writes migrated campaign")
		check(FileAccess.get_file_as_string(Save.legacy_file_path(3))==raw,"cancel leaves original exact")
		ui._activate("slot:3");ui._activate("migration_accept")
		check(ui.screen=="game" and ui.game.profile.world==pair[1] and ui.game.profile.credits==430,"accept starts safe previous world without granting money")
		check(not FileAccess.file_exists(Save.file_path(3)) and FileAccess.get_file_as_string(Save.legacy_file_path(3))==raw,"load is in-memory until explicit save")
	if not ui.has_method("_prepare_import"):
		failures.append("missing import preview and migration confirmation")
	else:
		remove_current(2)
		var old=Shop.create_profile();old.version=2;old.world=6;old.resume="playing"
		var raw=Save._encode(old)
		ui._show("save");ui._prepare_import(2,raw)
		check(ui.screen=="migration" and not FileAccess.file_exists(Save.file_path(2)),"legacy import waits before writing")
		ui._activate("migration_cancel")
		check(ui.screen=="save" and not FileAccess.file_exists(Save.file_path(2)),"cancel import preserves destination")
		ui._prepare_import(2,raw);ui._activate("migration_accept")
		check(Save.load_slot(2).ok and ui.game.profile.world==4 and ui.active_slot==2,"confirmed import saved and selected safely")
		var modern=Shop.create_profile();modern.world=5;modern.resume="rest";modern.credits=480;modern.upgrades.dano=1
		ui._prepare_import(2,Save._encode(modern))
		check(ui.screen=="rest" and ui.game.profile.world==5 and ui.game.profile.upgrades.dano==1,"modern import activates imported state before rest autosave")
		check(Save.load_slot(2).profile.world==5,"rest does not overwrite imported campaign with previous profile")
	var resting=Shop.create_profile();resting.world=2;resting.resume="rest";resting.cleared=[1,2];resting.rewarded={"1:0":true,"2:0":true}
	ui._start(resting,true);ui._activate("replay:1")
	check(ui.game.replay_return.resume=="rest" and ui.game.profile.resume=="playing","replay snapshots original rest before entering play")
	var completed=Shop.create_profile();completed.completed=true;completed.world=13;completed.resume="completed"
	var replay=completed.duplicate(true);replay.world=1;replay.resume="playing";replay.replay_mode=true;replay.replay_return=completed
	ui._start(replay,true)
	check(ui.screen=="game" and ui.game.state=="playing" and ui.game.replay,"completed campaign replay resumes as play, not victory")
	ui.sandbox=false;ui.active_slot=3;ui.difficulty="normal"
	seed(61245)
	var high_seeds=0
	for attempt in range(24):
		ui._new_profile()
		var generated=ui.game.profile.seed
		if generated>2147483647:high_seeds+=1
		var saved=Save.load_slot(3)
		check(saved.ok and saved.profile.seed==generated,"actual new-profile UI saves full uint32 seed attempt "+str(attempt))
	check(high_seeds>0,"UI creation includes naturally generated upper uint32 seeds")
	var refs=ui.audio._streams.values().map(func(v):return weakref(v))
	ui.queue_free();await process_frame
	for poll in range(100):
		if refs.all(func(r):return r.get_ref()==null):break
		await create_timer(.01).timeout
	restore_files()
	if failures.is_empty():print("CAMPAIGN12 MIGRATION UI PASS: old3/6 confirmation/cancel, import preview, rest autosave and completed replay");quit()
	else:printerr("CAMPAIGN12 MIGRATION UI FAIL: ",failures);quit(1)
