extends Node2D

@onready var task_container = $VBoxContainer
@onready var user_container = $VBoxContainer2
@onready var input = $input

var users_lib = {}

var user_buttons: Array[Button] = []
var selected_button: Button = null
var counter = 0
var current_user = ""
var adding_user = true

func _ready() -> void:
	for user_name in users_lib:
		_create_user_button(user_name)
	
	input.visible = false

func _create_user_button(user_name: String) -> Button:
	var user = Button.new()
	user.text = user_name
	_style_button(user)
	user_container.add_child(user)
	user.pressed.connect(_on_user_pressed.bind(user))
	user_buttons.append(user)
	return user

func _style_button(button: Button) -> StyleBoxFlat:
	var btn_bg = StyleBoxFlat.new()
	btn_bg.bg_color = Color(0.922, 0.0, 0.0, 1.0)
	btn_bg.corner_radius_bottom_left = 5
	btn_bg.corner_radius_bottom_right = 5
	btn_bg.corner_radius_top_left = 5
	btn_bg.corner_radius_top_right = 5
	btn_bg.border_width_bottom = 2
	btn_bg.border_width_top = 2
	btn_bg.content_margin_bottom = 8
	btn_bg.content_margin_top = 8
	
	button.add_theme_stylebox_override("normal", btn_bg)
	button.add_theme_stylebox_override("pressed", btn_bg)
	button.add_theme_stylebox_override("hover", btn_bg)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	
	return btn_bg

func _set_button_color(btn: Button, color: Color) -> void:
	var style = btn.get_theme_stylebox("normal")
	if style is StyleBoxFlat:
		style.bg_color = color

func _on_add_user_pressed() -> void:
	input.placeholder_text = "введите имя юзера"
	input.visible = true
	adding_user = true
	input.grab_focus()

func _on_add_task_pressed() -> void:
	input.placeholder_text = "введите задание"
	input.visible = true
	adding_user = false
	input.grab_focus()

func _input(event):
	if not input.visible:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER:
				var title = input.text.strip_edges()
				if title.is_empty():
					return
				
				if adding_user:
					_add_user(title)
				else:
					_add_task(title)
				
				input.text = ""
				input.visible = false
				input.release_focus()
			
			KEY_ESCAPE:
				input.text = ""
				input.visible = false
				input.release_focus()

func _add_user(title: String) -> void:
	if users_lib.has(title):
		input.placeholder_text = "такой юзер уже есть"
		return
	
	users_lib[title] = {}
	_create_user_button(title)

func _add_task(title: String) -> void:
	if current_user == "" or not users_lib.has(current_user):
		input.placeholder_text = "сначала выбери пользователя"
		input.visible = false
		return
	
	var task_id = counter
	counter += 1
	users_lib[current_user][task_id] = {"title": title, "stage": 0}
	_create_task_row(task_id, users_lib[current_user][task_id])

func _create_task_row(task_id: int, task_data: Dictionary) -> void:
	var task = Button.new()
	var task_style = _style_button(task)
	
	task.text = task_data["title"]
	_apply_color_changes(task_style, task_data["stage"])
	task.set_meta("color_stage", task_data["stage"])
	
	var delete_button = Button.new()
	delete_button.text = "завершить задачу"
	
	var hbox = HBoxContainer.new()
	hbox.add_child(task)
	hbox.add_child(delete_button)
	task_container.add_child(hbox)
	
	delete_button.pressed.connect(_on_delete_task.bind(hbox, task_id))
	task.pressed.connect(_on_task_color.bind(task, task_style, task_id))

func _apply_color_changes(style: StyleBoxFlat, stage: int):
	match stage:
		0:
			style.bg_color = Color(1.0, 0.0, 0.0, 1.0)
		1:
			style.bg_color = Color(1.0, 1.0, 0.0, 1.0)
		2:
			style.bg_color = Color(0.0, 1.0, 0.0, 1.0)

func _on_delete_task(row: Node, id: int) -> void:
	if current_user != "" and users_lib.has(current_user):
		users_lib[current_user].erase(id)
	row.queue_free()

func _on_task_color(btn: Button, style: StyleBoxFlat, task_id: int) -> void:
	var stage = btn.get_meta("color_stage", 0)
	stage = (stage + 1) % 3
	
	users_lib[current_user][task_id]["stage"] = stage
	
	btn.set_meta("color_stage", stage)
	_apply_color_changes(style, stage)

func _on_user_pressed(user: Button) -> void:
	selected_button = user
	current_user = user.text
	print("Выбран: ", current_user, " | users_lib: ", users_lib)
	
	for btn in user_buttons:
		if btn == selected_button:
			_set_button_color(btn, Color.GREEN)
		else:
			_set_button_color(btn, Color.RED)
	
	for child in task_container.get_children():
		child.queue_free()
	
	if not users_lib.has(current_user):
		return
	
	for task_id in users_lib[current_user]:
		var task_data = users_lib[current_user][task_id]
		_create_task_row(task_id, task_data)
