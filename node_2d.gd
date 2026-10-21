extends Node2D

@onready var task_container = $VBoxContainer
@onready var user_container = $VBoxContainer2
@onready var input = $input

var users_lib = {

}

var user_buttons = {}
var counter = 0
var current_user = ""
var adding_user = true

func _ready() -> void:
	
	for users in users_lib:
		var user = Button.new()
		user.text = users
		user_container.add_child(user)
		user.pressed.connect(_on_user_pressed.bind(user.text))
		
	input.visible = false

func _style_button(button: Button):
	var empty = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.0, 0.0, 0.0, 1.0)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))

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
	return btn_bg

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
				
				match adding_user:
					
					false:
						if current_user == "":
							input.placeholder_text = "сначала выбери пользователя"
							input.visible = false
							return
						var task_id = counter
						counter += 1
						users_lib[current_user][task_id] = title
				
						var delete_button = Button.new()
						delete_button.text = "завершить задачу"

						var task = Button.new()
						var task_style = _style_button(task)
						task.text = title

						var hbox = HBoxContainer.new()
						hbox.add_child(task)
						hbox.add_child(delete_button)
						task_container.add_child(hbox)
				
						delete_button.pressed.connect(_on_delete_task.bind(hbox, task_id))
						task.pressed.connect(_on_task_color.bind(task, task_style))

						input.text = ""
						input.visible = false
						
					true:
						users_lib[title] = {}
						var user = Button.new()
						user.text = title
						var user_style = _style_button(user)
						user_container.add_child(user)
						user.pressed.connect(_on_user_pressed.bind(user, user_style))
						
						input.text = ""
						input.visible = false

			KEY_ESCAPE:
				input.text = ""
				input.visible = false

func _on_delete_task(row: Node, id: int) -> void:
	if current_user != "" and users_lib.has(current_user):
		users_lib[current_user].erase(id)
		row.queue_free()

func _on_task_color(btn: Button, style: StyleBoxFlat) -> void:
	var stage = btn.get_meta("color_stage", 0)
	stage = (stage + 1) % 3
	btn.set_meta("color_stage", stage)

	match stage:
		0:
			style.bg_color = Color(1.0, 0.576, 0.781, 1.0)
		1:
			style.bg_color = Color(0.756, 0.589, 0.0, 1.0)
		2:
			style.bg_color = Color(0.0, 0.697, 0.226, 1.0)

func _on_user_pressed(user: Button, style: StyleBoxFlat) -> void:
	current_user = user.text
	print(users_lib)
	
	if task_container == null:
		return
	else:
		
		for child in task_container.get_children():
			task_container.remove_child(child)
			child.queue_free()
	for task_id in users_lib[current_user]:
		var task_body = users_lib[current_user][task_id]
		
		var task = Button.new()
		var task_style = _style_button(task)
		task.text = task_body
		
		var delete_button = Button.new()
		delete_button.text = "завершить задачу"
		
		var hbox = HBoxContainer.new()
		hbox.add_child(task)
		hbox.add_child(delete_button)
		task_container.add_child(hbox)
		
		delete_button.pressed.connect(_on_delete_task.bind(hbox, task_id))
		task.pressed.connect(_on_task_color.bind(task, task_style))
