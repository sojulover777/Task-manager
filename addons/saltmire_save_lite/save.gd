extends Node
## Saltmire Save Lite — one-line save/load for Godot 4 (free, MIT).
##
## The whole point: persist game state in a single call.
##     Save.write("slot1", {"hp": 80, "level": 3})
##     var d = Save.read("slot1")   # null if it doesn't exist
##
## API: write / read / has / erase / list_slots / autosave.
## Every write reports measurable numbers via stats() (bytes, write count).
##
## Need encryption, schema migration, backup + corruption recovery, gzip
## compression, smart (dirty-flag) autosave and slot metadata for a "Load Game"
## screen? That's Saltmire Save PRO → https://saltmire.itch.io/saltmire-save

signal saved(slot: String)
signal loaded(slot: String)

const DIR := "user://saltmire_saves/"

# ---- measurable stats (proof of value) -------------------------------------
var last_bytes: int = 0                  ## bytes written on the last save
var writes: int = 0                      ## total writes performed

var _autosave_slot: String = ""
var _autosave_cb: Callable = Callable()
var _timer: Timer = null


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)


## Write `data` (Dictionary/Array/primitive) to a named slot. Returns true on success.
func write(slot: String, data) -> bool:
	DirAccess.make_dir_recursive_absolute(DIR)
	var json := JSON.stringify({"data": data})
	var f := FileAccess.open(_path(slot), FileAccess.WRITE)
	if f == null:
		push_error("Saltmire Save Lite: cannot write " + _path(slot))
		return false
	f.store_string(json)
	f.close()
	last_bytes = json.to_utf8_buffer().size()
	writes += 1
	saved.emit(slot)
	return true


## Read a slot. Returns the stored data, or `null` if it doesn't exist / is unreadable.
func read(slot: String):
	if not FileAccess.file_exists(_path(slot)):
		return null
	var f := FileAccess.open(_path(slot), FileAccess.READ)
	if f == null:
		return null
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary) or not parsed.has("data"):
		return null
	loaded.emit(slot)
	return parsed.get("data")


func has(slot: String) -> bool:
	return FileAccess.file_exists(_path(slot))


## Delete a slot. Returns true if it existed.
func erase(slot: String) -> bool:
	var existed := has(slot)
	if existed:
		var d := DirAccess.open(DIR)
		if d:
			d.remove(slot + ".sav")
	return existed


func list_slots() -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(DIR)
	if d:
		for fn in d.get_files():
			if fn.ends_with(".sav"):
				out.append(fn.substr(0, fn.length() - 4))
	return out


## Autosave: writes `cb.call()` to `slot` every `interval` seconds.
func autosave(slot: String, cb: Callable, interval: float = 30.0) -> void:
	_autosave_slot = slot
	_autosave_cb = cb
	if _timer == null:
		_timer = Timer.new()
		add_child(_timer)
		_timer.timeout.connect(_on_autosave)
	_timer.wait_time = max(0.05, interval)
	_timer.start()


func stop_autosave() -> void:
	if _timer:
		_timer.stop()


func stats() -> Dictionary:
	return {
		"last_bytes": last_bytes,
		"writes": writes,
		"slots": list_slots().size(),
	}


func _on_autosave() -> void:
	if _autosave_cb.is_valid():
		write(_autosave_slot, _autosave_cb.call())


func _path(slot: String) -> String:
	return DIR + slot + ".sav"
