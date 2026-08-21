extends Control

func _ready():
	hide()
	var restart_btn = $VBoxContainer/RestartButton
	if restart_btn:
		restart_btn.pressed.connect(_go_to_main_menu)

	var copy_btn = $VBoxContainer/CopyStatsButton
	if copy_btn:
		copy_btn.pressed.connect(_on_copy_stats)

func _on_copy_stats():
	if StatTracker:
		var report = StatTracker.generate_report()
		DisplayServer.clipboard_set(report)

		var file = FileAccess.open("user://latest_run_report.txt", FileAccess.WRITE)
		if file:
			file.store_string(report)
			file.close()

		var copy_btn = $VBoxContainer/CopyStatsButton
		if copy_btn:
			copy_btn.text = "Copied!"
			var t = get_tree().create_timer(1.0)
			t.timeout.connect(func(): copy_btn.text = "Copy Stats Report")

func _go_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
