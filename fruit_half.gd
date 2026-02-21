extends RigidBody2D


@onready var sprite: Sprite2D = $Sprite2D

var fruit_type: String = "apple"
var is_left_half: bool = true

var fruit_half_textures = {
	"apple": "res://assets/sprites/appleHalf.png",
	"banana": "res://assets/sprites/bananaHalf.png",
	"watermelon": "res://assets/sprites/watermelonHalf.png",
	"pineapple": "res://assets/sprites/pineappleHalf.png",
	"kiwi": "res://assets/sprites/kiwiHalf.png",
	"strawberry": "res://assets/sprites/strawberryHalf.png",
	"mandarin": "res://assets/sprites/mandarinHalf.png",
	"lemon": "res://assets/sprites/lemonHalf.png",
	"grape": "res://assets/sprites/grapeHalf.png"
	
}

var fruit_full_textures = {
	"apple": "res://assets/sprites/apple.png",
	"banana": "resSS://assets/sprites/banana.png",
	"watermelon": "res://assets/sprites/watermelon.png",
	"pineapple": "res://assets/sprites/pineapple.png",
	"kiwi": "res://assets/sprites/kiwi.png",
	"strawberry": "res://assets/sprites/strawberry.png",
	"mandarin": "res://assets/sprites/mandarin.png",
	"lemon": "res://assets/sprites/lemon.png",
	"grape": "res://assets/sprites/grape.png"
}

func _ready() -> void:
	var tex_path: String = ""
	if fruit_type in fruit_half_textures:
		tex_path = fruit_half_textures[fruit_type]
		var texture = load(tex_path) as Texture2D
		if texture:
			sprite.texture = texture
			sprite.region_enabled = false
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
	
	var angle: float
	if is_left_half:
		angle = randf_range(PI/5, PI/4)
	else:
		angle = randf_range(3*PI/4, 4*PI/5)
	var speed = randf_range(380, 520)
	var direction = Vector2(cos(angle), sin(angle))
	apply_central_impulse(direction * speed)
	apply_torque_impulse(randf_range(-18, 18))

func _process(delta: float) -> void:
	if global_position.y > 2000:
		queue_free()
