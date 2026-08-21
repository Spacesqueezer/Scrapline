extends Node

const SAVE_PATH = "user://save_data.json"

var save_data = {
	"total_scrap": 0,
	"max_wave_reached": 0,
	"unlocked_modules": ["Miner", "Conveyor", "Weapon"]
}

func _ready():
	load_data()

func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found. Creating new save data.")
		save_data()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			if typeof(data) == TYPE_DICTIONARY:
				# Merge loaded data with default structure to prevent missing keys
				for key in data.keys():
					save_data[key] = data[key]
				print("Save data loaded successfully: ", save_data)
			else:
				print("Save data is not a dictionary.")
		else:
			print("JSON Parse Error: ", json.get_error_message())
		file.close()

func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		print("Save data saved successfully: ", save_data)
	else:
		print("Failed to open save file for writing.")

func add_scrap(amount: int):
	save_data["total_scrap"] += amount
	save_data()

func update_max_wave(wave: int):
	if wave > save_data["max_wave_reached"]:
		save_data["max_wave_reached"] = wave
		save_data()
