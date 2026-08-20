class_name GameOverMenu
extends Control

@onready var restart_button = $VBoxContainer/RestartButton

func _ready():
	hide()
	restart_button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed():
	# Перезагружаем текущую сцену
	get_tree().reload_current_scene()
