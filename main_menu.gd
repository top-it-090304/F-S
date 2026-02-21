extends Control

## Главное меню с кнопками Play и Settings

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton

var game_scene = preload("res://game.tscn")
var settings_scene = preload("res://settings.tscn")

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_packed(settings_scene)
