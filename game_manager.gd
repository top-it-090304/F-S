extends Node

## Менеджер игры - управляет состоянием игры, настройками и переходами между сценами

signal lives_changed(lives: int)
signal score_changed(score: int)
signal game_over

var lives: int = 3
var score: int = 0
var sound_enabled: bool = true
var music_enabled: bool = true

func _ready() -> void:
	load_settings()

func reset_game() -> void:
	lives = 3
	score = 0
	lives_changed.emit(lives)
	score_changed.emit(score)

func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("settings", "sound_enabled", sound_enabled)
	config.set_value("settings", "music_enabled", music_enabled)
	config.save("user://settings.cfg")

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		sound_enabled = config.get_value("settings", "sound_enabled", true)
		music_enabled = config.get_value("settings", "music_enabled", true)
