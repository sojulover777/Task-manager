extends Node2D

@onready var task_scroll = $ScrollContainer
@onready var task_container = $ScrollContainer/VBoxContainer
@onready var user_scroll = $ScrollContainer2
@onready var user_container = $ScrollContainer2/VBoxContainer2
@onready var input = $input

var users_lib = {}

var user_buttons: Array[Button] = []
var selected_button: Button = null
var counter = 0
var current_user = ""
var adding_user = true

var main_theme = preload("res://space-worm-theme/space_worm_theme.tres")
var delete_button_theme = preload("res://delete_button_theme.tres")
var red_icon = preload("res://red.png")
var orange_icon = preload("res://orange.png")
var green_icon = preload("res://green.png")

const SAVE_SLOT = "my_users_data"

func _ready() -> void:
	# 1. Загружаем данные при старте, если они есть
	_try_load_data()
	
	# Очищаем контейнер от возможных старых узлов (на всякий случай)
	for child in user_container.get_children():
		child.queue_free()
	user_buttons.clear()
	
	# 2. Создаем кнопки для загруженных пользователей
	for user_name in users_lib:
		_create_user_button(user_name)
	
	input.visible = false

# --- ФУНКЦИЯ ПЕРЕНОСА ТЕКСТА ---
func wrap_text(text: String, max_chars_per_line: int = 20) -> String:
	var words = text.split(" ")
	var lines = []
	var current_line = ""
	
	for word in words:
		if word.length() > max_chars_per_line:
			if current_line != "":
				lines.append(current_line)
				current_line = ""
			while word.length() > max_chars_per_line:
				lines.append(word.substr(0, max_chars_per_line))
				word = word.substr(max_chars_per_line)
			current_line = word
			continue
		
		if current_line.length() + word.length() + 1 > max_chars_per_line:
			lines.append(current_line)
			current_line = word
		else:
			if current_line != "":
				current_line += " "
			current_line += word
	
	if current_line != "":
		lines.append(current_line)
	
	return "\n".join(lines)

# --- СОЗДАНИЕ UI ---
func _create_user_button(user_name: String) -> Button:
	var hbox = HBoxContainer.new()
	
	var user = Button.new()
	user.text = wrap_text(user_name, 10) 
	user.set_meta("raw_name", user_name) 
	user.theme =  main_theme
	user.icon = red_icon
	user.add_theme_constant_override("icon_max_width", 16)
	user.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Растягиваем кнопку юзера
	
	var delete_user = Button.new()
	delete_user.text = "X"
	delete_user.theme = delete_button_theme
	delete_user.tooltip_text = "Удалить пользователя"
	
	hbox.add_child(user)
	hbox.add_child(delete_user)
	user_container.add_child(hbox)
		
	user.pressed.connect(_on_user_pressed.bind(user))
	# Передаем кнопку пользователя и контейнер, чтобы удалить всё разом
	delete_user.pressed.connect(_on_delete_user.bind(user, hbox))
	
	user_buttons.append(user)
	return user

func _create_task_row(task_id: String, task_data: Dictionary) -> void:
	var task = Button.new()
	
	# Приводим stage к int при загрузке
	var current_stage = int(task_data["stage"])
	
	task.text = wrap_text(task_data["title"], 38)
	task.theme = main_theme
	_apply_color_changes(task, current_stage)
	task.add_theme_constant_override("icon_max_width", 16)
	task.set_meta("color_stage", current_stage)
	
	task.custom_minimum_size = Vector2(250, 0) 
	task.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	task.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var delete_button = Button.new()
	delete_button.text = "завершить задачу"
	delete_button.theme = delete_button_theme
	delete_button.size_flags_horizontal = Control.SIZE_SHRINK_END 
	
	var hbox = HBoxContainer.new()
	hbox.add_child(task)
	hbox.add_child(delete_button)
	
	task_container.add_child(hbox)
		
	delete_button.pressed.connect(_on_delete_task.bind(hbox, task_id))
	task.pressed.connect(_on_task_color.bind(task, task_id))

func _apply_color_changes(btn: Button, stage: int):
	match int(stage):
		0: btn.icon = red_icon
		1: btn.icon = orange_icon
		2: btn.icon = green_icon

# --- ДОБАВЛЕНИЕ ДАННЫХ ---
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
	
	if user_scroll:
		await get_tree().process_frame 
		user_scroll.scroll_vertical = user_scroll.get_v_scroll_bar().max_value

func _add_task(title: String) -> void:
	if current_user == "" or not users_lib.has(current_user):
		input.placeholder_text = "сначала выбери пользователя"
		input.visible = false
		return
	
	var task_id = str(counter) 
	counter += 1
	
	users_lib[current_user][task_id] = {"title": title, "stage": 0}
	_create_task_row(task_id, users_lib[current_user][task_id])
	
	if task_scroll:
		await get_tree().process_frame
		task_scroll.scroll_vertical = task_scroll.get_v_scroll_bar().max_value

# --- СОБЫТИЯ КНОПОК ЗАДАЧ ---
func _on_delete_task(row: Node, id: String) -> void:
	if current_user != "" and users_lib.has(current_user):
		users_lib[current_user].erase(id)
	row.queue_free()

func _on_task_color(btn: Button, task_id: String) -> void:
	var stage = int(btn.get_meta("color_stage", 0))
	stage = (stage + 1) % 3
	
	users_lib[current_user][task_id]["stage"] = stage
	
	btn.set_meta("color_stage", stage)
	_apply_color_changes(btn, stage)

# --- СОБЫТИЯ КНОПОК ПОЛЬЗОВАТЕЛЕЙ ---
func _on_delete_user(user: Button, hbox: HBoxContainer):
	var user_name = user.get_meta("raw_name", user.text)
	
	# 1. Удаляем из словаря
	users_lib.erase(user_name)
	
	# 2. Удаляем из массива кнопок
	user_buttons.erase(user)
	
	# 3. Удаляем визуал (кнопку и контейнер)
	hbox.queue_free()
	
	# 4. Если удалили текущего выбранного - очищаем задачи
	if current_user == user_name:
		current_user = ""
		selected_button = null
		for child in task_container.get_children():
			child.queue_free()
			
	# 5. Автосохранение
	Save.write(SAVE_SLOT, users_lib)
	print("Пользователь ", user_name, " удален.")

func _on_user_pressed(user: Button) -> void:
	selected_button = user
	current_user = user.get_meta("raw_name", user.text) 
	
	for btn in user_buttons:
		if btn == selected_button:
			btn.icon = green_icon
		else:
			btn.icon = red_icon
	
	# Очищаем список задач
	if task_container:
		for child in task_container.get_children():
			child.queue_free()
	
	if not users_lib.has(current_user):
		return
	
	# Загружаем задачи выбранного юзера
	for task_id in users_lib[current_user]:
		var task_data = users_lib[current_user][task_id]
		_create_task_row(task_id, task_data)
	
	if task_scroll:
		await get_tree().process_frame
		task_scroll.scroll_vertical = 0

# --- СОХРАНЕНИЕ И ЗАГРУЗКА ---
func _on_save_pressed() -> void:
	Save.write(SAVE_SLOT, users_lib)
	print("💾 Данные сохранены. Пользователей: ", users_lib.size())

func _on_load_pressed() -> void:
	_try_load_data()
	
	if not users_lib.is_empty():
		print("📥 Данные загружены. Пользователей: ", users_lib.size())
		
		# ИСПРАВЛЕНО: Очищаем контейнеры целиком, а не только массив кнопок
		for child in user_container.get_children():
			child.queue_free()
		user_buttons.clear()
		
		for child in task_container.get_children():
			child.queue_free()
		
		current_user = ""
		selected_button = null
		
		# Создаем кнопки заново
		for user_name in users_lib:
			_create_user_button(user_name)
	else:
		print("📂 Сохранений не найдено.")

func _try_load_data() -> void:
	var loaded_data = Save.read(SAVE_SLOT)
	
	if loaded_data != null and loaded_data is Dictionary:
		users_lib = loaded_data
		
		# Восстанавливаем счетчик, чтобы новые задачи не перезаписывали старые
		var max_id = 0
		for user_name in users_lib:
			for task_key in users_lib[user_name]:
				var id_num = int(task_key)
				if id_num >= max_id:
					max_id = id_num + 1
		counter = max_id
