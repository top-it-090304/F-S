extends Control

## Основная игровая сцена

@onready var game_area: Control = $GameArea
@onready var lives_label: Label = $UI/LivesLabel
@onready var score_label: Label = $UI/ScoreLabel
@onready var countdown_label: Label = $UI/CountdownLabel
@onready var bomb_message: Label = $UI/BombMessage
@onready var spawn_timer: Timer = $SpawnTimer
@onready var stain_timer: Timer = $StainTimer
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var game_over_score_label: Label = $UI/GameOverPanel/VBoxContainer/ScoreContainer/ScoreLabel
@onready var watermelon_half_sprite: Sprite2D = $UI/GameOverPanel/VBoxContainer/ScoreContainer/WatermelonHalfSprite
@onready var continue_button: Button = $UI/GameOverPanel/VBoxContainer/ContinueButton

# Для отрисовки линии разреза
var cut_line_points: Array[Vector2] = []

var game_manager: Node
var is_game_active: bool = false
var touch_path: Array[Vector2] = []
var fruits: Array[RigidBody2D] = []
var stains: Array[Node] = []
var is_dragging: bool = false

var fruit_scene = preload("res://fruit.tscn")
var fruit_half_scene = preload("res://fruit_half.tscn")
var stain_scene = preload("res://stain.tscn")
var main_menu_scene = preload("res://main_menu.tscn")

func _ready() -> void:
	
	if ResourceLoader.exists("res://main_menu.tscn"):
		main_menu_scene = preload("res://main_menu.tscn")
		print("main_menu.tscn загружен")
	else:
		print("main_menu.tscn НЕ НАЙДЕН!")
	
	game_manager = get_node("/root/GameManager")
	game_manager.reset_game()
	game_manager.lives_changed.connect(_on_lives_changed)
	game_manager.score_changed.connect(_on_score_changed)
	game_manager.game_over.connect(_on_game_over)
	
	start_countdown()
	
	bomb_message.visible = false
	game_over_panel.visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	



func start_countdown() -> void:
	countdown_label.visible = true
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "3"
	countdown_label.modulate.a = 1.0
	
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "2"
	
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "1"
	
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "НАЧАЛИ!"
	
	await get_tree().create_timer(0.5).timeout
	countdown_label.visible = false
	is_game_active = true
	
	# Курсор = нож
	_set_knife_cursor()
	
	# Запускаем спавн фруктов
	spawn_timer.wait_time = 0.75
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	# Запускаем таймер для создания новых пятен
	stain_timer.wait_time = 0.5
	stain_timer.timeout.connect(_on_stain_timer_timeout)
	stain_timer.start()

func _on_spawn_timer_timeout() -> void:
	if not is_game_active:
		return

	spawn_fruit()
	spawn_fruit()
	spawn_fruit()  
	# spawn_fruit()

	


func spawn_fruit() -> void:
	var fruit = fruit_scene.instantiate() as RigidBody2D
	var x = randf_range(100, 980)
	
	if randf() < 0.1:
		fruit.is_bomb = true
	else:
		var fruit_types = ["apple", "banana", "watermelon", "pineapple", "kiwi", "strawberry", "mandarin", "lemon", "grape"]
		fruit.fruit_type = fruit_types[randi() % fruit_types.size()]
	
	fruits.append(fruit)
	game_area.add_child(fruit)
	fruit.global_position = Vector2(x, 1850)

func _touch_to_canvas(screen_pos: Vector2) -> Vector2:
	var vp = get_viewport()
	return vp.get_canvas_transform().affine_inverse() * screen_pos

func _set_knife_cursor() -> void:
	var size = 48
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var tip = Vector2(size - 2, size - 2)
	var base = Vector2(4, 4)
	for x in range(size):
		for y in range(size):
			var p = Vector2(x, y)
			var d = _point_to_segment_distance(p, base, tip)
			if d <= 3.0:
				var a = 1.0 - d / 3.0
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a * 0.95))
			elif d <= 5.0:
				var a = (1.0 - (d - 3.0) / 2.0) * 0.5
				img.set_pixel(x, y, Color(0.7, 0.85, 1.0, a))
	# Кончик ножа — точка, по которой режем 
	Input.set_custom_mouse_cursor(img, Input.CURSOR_ARROW, Vector2(size - 4, size - 4))

func _point_to_segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var ap = p - a
	var t = clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
	var proj = a + t * ab
	return p.distance_to(proj)

func _continue_button_hit(screen_pos: Vector2) -> bool:
	var canvas_pos = _touch_to_canvas(screen_pos)
	var button_rect = Rect2(continue_button.global_position, continue_button.size)
	return button_rect.grow(10.0).has_point(canvas_pos)

func _input(event: InputEvent) -> void:
	if game_over_panel.visible:
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
			var pos = event.position
			if _continue_button_hit(pos):
				_on_continue_pressed()
				if get_viewport():  
					get_viewport().set_input_as_handled()
				return
		return
	
	if not is_game_active:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var canvas_pos = _touch_to_canvas(event.position)
			if event.pressed:
				touch_path.clear()
				cut_line_points.clear()
				touch_path.append(canvas_pos)
				cut_line_points.append(canvas_pos)
				is_dragging = true
				queue_redraw()
			else:
				if touch_path.size() > 1:
					check_cuts()
				touch_path.clear()
				cut_line_points.clear()
				is_dragging = false
				queue_redraw()
	
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var canvas_pos = _touch_to_canvas(event.position)
		touch_path.append(canvas_pos)
		cut_line_points = touch_path.duplicate()
		queue_redraw()
		check_cuts_continuous()
	
	# Сенсор 
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_path.clear()
			cut_line_points.clear()
			var canvas_pos = _touch_to_canvas(event.position)
			touch_path.append(canvas_pos)
			cut_line_points.append(canvas_pos)
			is_dragging = true
			queue_redraw()
		else:
			if touch_path.size() > 1:
				check_cuts()
			touch_path.clear()
			cut_line_points.clear()
			is_dragging = false
			queue_redraw()
	
	if event is InputEventScreenDrag:
		if is_dragging:
			var canvas_pos = _touch_to_canvas(event.position)
			touch_path.append(canvas_pos)
			cut_line_points = touch_path.duplicate()
			queue_redraw()
			check_cuts_continuous()

func _draw() -> void:
	if not is_game_active or game_over_panel.visible:
		return
	
	if cut_line_points.size() >= 2:
		for i in range(cut_line_points.size() - 1):
			var start = cut_line_points[i]
			var end = cut_line_points[i + 1]
			draw_line(start, end, Color(0.9, 0.95, 1.0, 0.95), 8.0)
			draw_line(start, end, Color(0.6, 0.85, 1.0, 0.9), 5.0)
			draw_line(start, end, Color(1.0, 1.0, 1.0, 0.8), 2.0)

func check_cuts() -> void:
	if touch_path.size() < 2:
		return
	
	check_cuts_continuous()

func check_cuts_continuous() -> void:
	if touch_path.size() < 2:
		return

	var cut_fruits: Array[RigidBody2D] = []
	
	for i in range(touch_path.size() - 1):
		var start = touch_path[i]
		var end = touch_path[i + 1]
		
		for fruit in fruits.duplicate():
			if fruit == null or not is_instance_valid(fruit) or fruit in cut_fruits:
				continue
			
			var fruit_pos = fruit.global_position
			var distance = point_to_line_distance(fruit_pos, start, end)
			# Радиус попадания ножа по фрукту 
			var hit_radius = 55.0
			if distance < hit_radius:
				cut_fruits.append(fruit)
				cut_fruit(fruit, fruit_pos)
				break

func point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line = line_end - line_start
	var line_length = line.length()
	if line_length == 0:
		return point.distance_to(line_start)
	
	var t = max(0, min(1, (point - line_start).dot(line) / (line_length * line_length)))
	var projection = line_start + t * line
	return point.distance_to(projection)

func cut_fruit(fruit: RigidBody2D, cut_position: Vector2) -> void:
	if not is_instance_valid(fruit):
		return
	
	if fruit.is_bomb:
		handle_bomb_cut()
		fruit.queue_free()
		fruits.erase(fruit)
		return
	
	# Создаем две половинки
	create_fruit_halves(fruit, cut_position)
	
	# Создаем пятно
	create_stain(cut_position)
	
	# Добавляем очки
	game_manager.add_score(10)
	
	# Удаляем фрукт
	fruit.queue_free()
	fruits.erase(fruit)

func create_fruit_halves(fruit: RigidBody2D, position: Vector2) -> void:
	var spread = 55.0
	# Левая половина — уходит влево и вниз
	var half1 = fruit_half_scene.instantiate()
	half1.global_position = position + Vector2(-spread, 0)
	half1.fruit_type = fruit.fruit_type
	half1.is_left_half = true
	game_area.add_child(half1)
	
	# Правая половина — уходит вправо и вниз
	var half2 = fruit_half_scene.instantiate()
	half2.global_position = position + Vector2(spread, 0)
	half2.fruit_type = fruit.fruit_type
	half2.is_left_half = false
	game_area.add_child(half2)
	
	# Брызги
	create_splatter(position, fruit.fruit_type)

func create_stain(position: Vector2) -> void:
	var stain = stain_scene.instantiate()
	stain.global_position = position
	game_area.add_child(stain)
	stains.append(stain)

func create_splatter(position: Vector2, fruit_type: String) -> void:
	for i in range(8):
		var splatter = stain_scene.instantiate()
		var angle = (PI * 2 / 8) * i
		var distance = randf_range(20, 60)
		splatter.global_position = position + Vector2(cos(angle), sin(angle)) * distance
		
		var color = Color(1.0, 0.2, 0.2, 0.6)  # Красный по умолчанию
		match fruit_type:
			"banana":
				color = Color(1.0, 0.9, 0.2, 0.6)
			"watermelon":
				color = Color(1.0, 0.3, 0.3, 0.6) 
			"orange", "peach", "mandarin":
				color = Color(1.0, 0.6, 0.2, 0.6) 
			"grape":
				color = Color(0.6, 0.2, 0.8, 0.6)
			"kiwi":
				color = Color(0.6, 0.9, 0.3, 0.6)
			"cherry", "strawberry":
				color = Color(1.0, 0.1, 0.1, 0.6)
		
		splatter.modulate = color
		game_area.add_child(splatter)

func _on_stain_timer_timeout() -> void:
	if randf() < 0.2 and is_game_active:
		var x = randf_range(100, 980)
		var y = randf_range(200, 1700)
		create_stain(Vector2(x, y))

func handle_bomb_cut() -> void:
	bomb_message.text = "Упс, вы разрезали бомбу!"
	bomb_message.visible = true
	
	await get_tree().create_timer(2.0).timeout
	bomb_message.visible = false

	game_manager.lose_life()

func _on_lives_changed(new_lives: int) -> void:
	lives_label.text = "Жизни: " + str(new_lives)

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Очки: " + str(new_score)

func _on_game_over() -> void:
	is_game_active = false
	spawn_timer.stop()
	stain_timer.stop()
	touch_path.clear()
	cut_line_points.clear()
	is_dragging = false
	queue_redraw()

	Input.set_custom_mouse_cursor(null)
	
	show_game_over_banner()

func show_game_over_banner() -> void:
	game_over_score_label.text = str(game_manager.score)
	var watermelon_half_texture = load("res://assets/sprites/watermelonHalf.png")
	if watermelon_half_texture:
		watermelon_half_sprite.texture = watermelon_half_texture

	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	
	continue_button.disabled = false
	continue_button.visible = true
	
	var tween = create_tween()
	tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.6)
	
func clear_game_objects() -> void:
	for fruit in fruits:
		if is_instance_valid(fruit):
			fruit.queue_free()
	fruits.clear()
	
	for stain in stains:
		if is_instance_valid(stain):
			stain.queue_free()
	stains.clear()
	
	touch_path.clear()
	cut_line_points.clear()
	is_dragging = false
	queue_redraw()

func _on_continue_pressed() -> void:
	print("Переход на главное меню")
	
	is_game_active = false
	spawn_timer.stop()
	stain_timer.stop()
	
	clear_game_objects()
	
	game_over_panel.visible = false
	bomb_message.visible = false
	
	get_tree().change_scene_to_file("res://main_menu.tscn")
	
