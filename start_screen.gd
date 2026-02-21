extends Control

## Экран запуска с анимацией увеличения фрукта

@onready var fruit_sprite: Sprite2D = $FruitSprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer

var main_menu_scene = preload("res://main_menu.tscn")

func _ready() -> void:
	fruit_sprite.scale = Vector2(0.1, 0.1)
	fruit_sprite.modulate.a = 0.0
	
	animation_player.play("fruit_grow")
	
	timer.wait_time = 2.5
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout() -> void:
	get_tree().change_scene_to_packed(main_menu_scene)
