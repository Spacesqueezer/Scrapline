extends Control

func _ready():
	var btn = $VBoxContainer/RestartButton
	if btn:
		# Переписываем логику: теперь при проигрыше мы идем в Главное меню
		if btn.pressed.is_connected(_on_restart):
			btn.pressed.disconnect(_on_restart)
		btn.text = "Back to Main Menu"
		btn.pressed.connect(_go_to_main_menu)

func _go_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_restart():
	get_tree().reload_current_scene()
