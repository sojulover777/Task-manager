extends Control
## Visible, measurable demo of Saltmire Save Lite.
## Runs the core API live and prints REAL numbers to the screen.

@onready var log_label: RichTextLabel = $Panel/Margin/Log


func _ready() -> void:
	log_label.clear()
	log_label.bbcode_enabled = true
	_line("[b]Saltmire Save Lite — live proof[/b]\n")
	await get_tree().create_timer(0.4).timeout

	Save.write("player", {"hp": 80, "level": 3})
	var d = Save.read("player")
	_ok("write + read in one line — hp=%d level=%d" % [d.hp, d.level])
	await get_tree().create_timer(0.6).timeout

	Save.write("options", {"volume": 0.8, "lang": "en"})
	_ok("second slot saved — %d bytes on disk" % Save.last_bytes)
	await get_tree().create_timer(0.6).timeout

	_ok("has('player') = %s   has('ghost') = %s" % [Save.has("player"), Save.has("ghost")])
	await get_tree().create_timer(0.6).timeout

	_ok("read('ghost') = %s (safe null, no crash)" % Save.read("ghost"))
	await get_tree().create_timer(0.6).timeout

	_ok("list_slots() = %s" % [Save.list_slots()])
	await get_tree().create_timer(0.6).timeout

	Save.erase("options")
	_ok("erase('options') → list_slots() = %s" % [Save.list_slots()])
	await get_tree().create_timer(0.6).timeout

	var st = Save.stats()
	_line("\n[color=#7CFC98][b]writes=%d  last_bytes=%d  slots=%d[/b][/color]" %
		[st.writes, st.last_bytes, st.slots])
	_line("[color=#8CB4FF]Need encryption · migration · backup · compression?[/color]")
	_line("[color=#FFD86B]→ Saltmire Save PRO[/color]")


func _line(t: String) -> void:
	log_label.append_text(t + "\n")


func _ok(t: String) -> void:
	_line("[color=#7CFC98]>[/color] " + t)
