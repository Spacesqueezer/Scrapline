extends Node

const SAVE_PATH = "user://save_data.json"

var save_data = {
	"total_scrap": 0,
	"max_wave_reached": 0,
	# Изменяем структуру на словарь для поддержки уровней улучшений
	"modules": {
		"Miner": {"unlocked": true, "level": 1},
		"Conveyor": {"unlocked": true, "level": 1},
		"Weapon": {"unlocked": true, "level": 1},
		"Shotgun": {"unlocked": false, "level": 0},
		"Splitter": {"unlocked": false, "level": 0},
		"Modifier": {"unlocked": false, "level": 0}
	}
}

func _ready():
	load_data()

func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found. Creating new save data.")
		save_to_disk()
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

func save_to_disk():
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
	save_to_disk()

func update_max_wave(wave: int):
	if wave > save_data["max_wave_reached"]:
		save_data["max_wave_reached"] = wave
		save_to_disk()

# Новые методы для управления Мета-магазином
func is_module_unlocked(module_name: String) -> bool:
	if save_data["modules"].has(module_name):
		return save_data["modules"][module_name]["unlocked"]
	return false

func get_module_level(module_name: String) -> int:
	if save_data["modules"].has(module_name):
		return save_data["modules"][module_name]["level"]
	return 0

func unlock_module(module_name: String, cost: int) -> bool:
	if save_data["total_scrap"] >= cost and not is_module_unlocked(module_name):
		save_data["total_scrap"] -= cost
		if not save_data["modules"].has(module_name):
			save_data["modules"][module_name] = {"unlocked": true, "level": 1}
		else:
			save_data["modules"][module_name]["unlocked"] = true
			save_data["modules"][module_name]["level"] = 1
		save_to_disk()
		return true
	return false

func upgrade_module(module_name: String, cost: int) -> bool:
	if save_data["total_scrap"] >= cost and is_module_unlocked(module_name):
		save_data["total_scrap"] -= cost
		save_data["modules"][module_name]["level"] += 1
		save_to_disk()
		return true
	return false
