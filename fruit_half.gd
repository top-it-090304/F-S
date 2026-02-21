extends RigidBody2D

## Половина разрезанного фрукта. Использует pineappleHalf.png и т.д. где есть, иначе половинку из целого.

@onready var sprite: Sprite2D = $Sprite2D

var fruit_type: String = "apple"
var is_left_half: bool = true

# Текстуры половинок (как pineappleHalf.png) — при разрезе показываем их
var fruit_half_textures = {
	"apple": "res://assets/sprites/appleHalf.png",
	"banana": "res://assets/sprites/bananaHalf.png",
	"watermelon": "res://assets/sprites/watermelonHalf.png",
	"pineapple": "res://assets/sprites/pineappleHalf.png",
	"kiwi": "res://assets/sprites/kiwiHalf.png",
	"strawberry": "res://assets/sprites/strawberryHalf.png"
}

# Целые фрукты (для тех, у кого нет Half — режем текстуру пополам)
var fruit_full_textures = {
	"apple": "res://assets/sprites/apple.png",
	"banana": "res://assets/sprites/banana.png",
	"watermelon": "res://assets/sprites/watermelon.png",
	"pineapple": "res://assets/sprites/pineapple.png",
	"kiwi": "res://assets/sprites/kiwi.png",
	"strawberry": "res://assets/sprites/strawberry.png"
}

func _ready() -> void:
	# Сначала пробуем текстуру половинки (pineappleHalf и т.д.)
	var tex_path: String = ""
	if fruit_type in fruit_half_textures:
		tex_path = fruit_half_textures[fruit_type]
		var texture = load(tex_path) as Texture2D
		if texture:
			sprite.texture = texture
			sprite.region_enabled = false
			# Половинка — одна картинка; вторая половина — отражённая или та же
			sprite.scale = Vector2(0.35, 0.35)
			if not is_left_half:
				sprite.flip_h = true
			sprite.position.x = 10 if is_left_half else -10
	if not sprite.texture and fruit_type in fruit_full_textures:
		tex_path = fruit_full_textures[fruit_type]
		var texture = load(tex_path) as Texture2D
		if texture:
			sprite.texture = texture
			sprite.region_enabled = true
			var tw = texture.get_width()
			var th = texture.get_height()
			if is_left_half:
				sprite.region_rect = Rect2(0, 0, tw / 2, th)
				sprite.position.x = -8
			else:
				sprite.region_rect = Rect2(tw / 2, 0, tw / 2, th)
				sprite.position.x = 8
			sprite.scale = Vector2(0.35, 0.35)
	
	# Падение вниз с широким разлётом в стороны (разрез заметно раздвигает половинки)
	var angle: float
	if is_left_half:
		angle = randf_range(PI/5, PI/4)   # влево-вниз
	else:
		angle = randf_range(3*PI/4, 4*PI/5)  # вправо-вниз
	var speed = randf_range(380, 520)
	var direction = Vector2(cos(angle), sin(angle))
	apply_central_impulse(direction * speed)
	apply_torque_impulse(randf_range(-18, 18))

func _process(delta: float) -> void:
	# Удаляем половинку, если она упала за экран
	if global_position.y > 2000:
		queue_free()
