extends RigidBody2D

## Фрукт, который можно разрезать

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var fruit_type: String = "apple"
var is_bomb: bool = false
var velocity: Vector2 = Vector2.ZERO

# Список доступных фруктов
var fruit_textures = {
	"apple": "res://assets/sprites/apple.png",
	"banana": "res://assets/sprites/banana.png",
	"watermelon": "res://assets/sprites/watermelon.png",
	"pineapple": "res://assets/sprites/pineapple.png",
	"kiwi": "res://assets/sprites/kiwi.png",
	"strawberry": "res://assets/sprites/strawberry.png"
}

func _ready() -> void:
	# Устанавливаем текстуру фрукта
	if fruit_type in fruit_textures:
		var texture = load(fruit_textures[fruit_type])
		if texture:
			sprite.texture = texture
	
	# Маленькие фрукты (как на референсе)
	sprite.scale = Vector2(0.4, 0.4)
	
	# Летят почти прямо вверх до самого верха экрана
	var angle = randf_range(-PI/2 - 0.12, -PI/2 + 0.12)  # ±~7° от вертикали
	var speed = randf_range(820, 1050)  # хватает до верха экрана (1920)
	velocity = Vector2(cos(angle), sin(angle)) * speed
	
	gravity_scale = 0.55  # чуть слабее гравитация — долетают до верха
	apply_central_impulse(velocity)
	apply_torque_impulse(randf_range(-5, 5))
	
	# Настройка внешнего вида бомбы
	if is_bomb:
		modulate = Color(0.3, 0.3, 0.3)
		sprite.texture = null  # Можно добавить текстуру бомбы

func _process(delta: float) -> void:
	# Удаляем фрукт, если он упал за экран
	if global_position.y > 2000:
		queue_free()
