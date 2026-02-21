extends Sprite2D

## Пятно от разрезанного фрукта

var fade_time: float = 3.0
var elapsed_time: float = 0.0

func _ready() -> void:
	var circle_image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center = Vector2(32, 32)
	for x in range(64):
		for y in range(64):
			var dist = center.distance_to(Vector2(x, y))
			if dist < 30:
				var alpha = 1.0 - (dist / 30.0)
				circle_image.set_pixel(x, y, Color(1.0, 0.2, 0.2, alpha * 0.8))
	
	var circle_texture = ImageTexture.create_from_image(circle_image)
	texture = circle_texture

func _process(delta: float) -> void:
	elapsed_time += delta
	var alpha = 1.0 - (elapsed_time / fade_time)
	modulate.a = max(0.0, alpha)
	
	if alpha <= 0:
		queue_free()
