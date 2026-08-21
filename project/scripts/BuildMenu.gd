class_name BuildMenu
extends Control

@onready var build_buttons_container = $VBoxContainer/HBoxContainer
@onready var start_wave_button = $VBoxContainer/StartWaveButton
@onready var state_label = $VBoxContainer/StateLabel
@onready var wave_label = $VBoxContainer/WaveLabel
@onready var base_hp_label = $VBoxContainer/BaseHPLabel
@onready var selected_label = $VBoxContainer/SelectedLabel
@onready var test_scenario_button = $VBoxContainer/TestScenarioButton

signal on_building_selected(building_type: String)
signal on_start_wave_pressed()
signal on_test_scenario_pressed()

var unlocked_buildings: Array[String] = ["Miner", "Conveyor", "Weapon"]
var building_buttons: Dictionary = {}

func _ready():
	# Если есть сохранения, парсим разблокированные модули из новой структуры словаря
	if SaveManager and SaveManager.save_data.has("modules"):
		unlocked_buildings.clear()
		var mods = SaveManager.save_data["modules"]
		for m_name in mods.keys():
			if mods[m_name].has("unlocked") and mods[m_name]["unlocked"]:
				unlocked_buildings.append(m_name)

	# Ensure the UI doesn't block grid clicks where it's transparent
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	$VBoxContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$VBoxContainer/HBoxContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	start_wave_button.pressed.connect(func(): on_start_wave_pressed.emit())

	if test_scenario_button:
		test_scenario_button.pressed.connect(func(): on_test_scenario_pressed.emit())

	# Connect build buttons (Mocking UI data for now)
	_create_building_button("Miner")
	_create_building_button("Conveyor")
	_create_building_button("Weapon")
	_create_building_button("Modifier")
	_create_building_button("Shotgun")
	_create_building_button("Splitter")

	var btn_delete = Button.new()
	btn_delete.text = "Delete"
	btn_delete.pressed.connect(func(): on_building_selected.emit("Delete"))
	build_buttons_container.add_child(btn_delete)

	var btn_rotate = Button.new()
	btn_rotate.text = "Rotate"
	btn_rotate.pressed.connect(func(): on_building_selected.emit("Rotate"))
	build_buttons_container.add_child(btn_rotate)

	# Connect to own signal to update visual label
	on_building_selected.connect(func(type): selected_label.text = "Selected: " + type)

func _create_building_button(b_name: String):
	var btn = Button.new()
	btn.text = b_name
	btn.pressed.connect(func(): on_building_selected.emit(b_name))
	build_buttons_container.add_child(btn)
	building_buttons[b_name] = btn

	if b_name not in unlocked_buildings:
		btn.hide()

func unlock_building(b_name: String):
	if b_name not in unlocked_buildings:
		unlocked_buildings.append(b_name)
	if building_buttons.has(b_name):
		building_buttons[b_name].show()

func update_state_label(state_name: String):
	state_label.text = "State: " + state_name
	start_wave_button.disabled = (state_name != "BUILD")
	if test_scenario_button:
		test_scenario_button.disabled = (state_name != "BUILD")

func update_wave_label(wave: int):
	wave_label.text = "Wave: " + str(wave)

func update_energy(current: int, max: int):
	base_hp_label.text = "Energy: " + str(current) + " / " + str(max)
