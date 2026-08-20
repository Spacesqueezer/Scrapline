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

func _ready():
	# Ensure the UI doesn't block grid clicks where it's transparent
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	$VBoxContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$VBoxContainer/HBoxContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	start_wave_button.pressed.connect(func(): on_start_wave_pressed.emit())

	if test_scenario_button:
		test_scenario_button.pressed.connect(func(): on_test_scenario_pressed.emit())

	# Connect build buttons (Mocking UI data for now)
	var btn_miner = Button.new()
	btn_miner.text = "Miner"
	btn_miner.pressed.connect(func(): on_building_selected.emit("Miner"))
	build_buttons_container.add_child(btn_miner)

	var btn_modifier = Button.new()
	btn_modifier.text = "Modifier"
	btn_modifier.pressed.connect(func(): on_building_selected.emit("Modifier"))
	build_buttons_container.add_child(btn_modifier)

	var btn_weapon = Button.new()
	btn_weapon.text = "Weapon"
	btn_weapon.pressed.connect(func(): on_building_selected.emit("Weapon"))
	build_buttons_container.add_child(btn_weapon)

	var btn_shotgun = Button.new()
	btn_shotgun.text = "Shotgun"
	btn_shotgun.pressed.connect(func(): on_building_selected.emit("Shotgun"))
	build_buttons_container.add_child(btn_shotgun)

	var btn_splitter = Button.new()
	btn_splitter.text = "Splitter"
	btn_splitter.pressed.connect(func(): on_building_selected.emit("Splitter"))
	build_buttons_container.add_child(btn_splitter)

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

func update_state_label(state_name: String):
	state_label.text = "State: " + state_name
	start_wave_button.disabled = (state_name != "BUILD")
	if test_scenario_button:
		test_scenario_button.disabled = (state_name != "BUILD")

func update_wave_label(wave: int):
	wave_label.text = "Wave: " + str(wave)

func update_base_hp(hp: int):
	base_hp_label.text = "Base HP: " + str(hp)
