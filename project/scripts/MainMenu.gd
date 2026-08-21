extends Control

@onready var scrap_label = $VBoxContainer/ScrapLabel
@onready var shop_container = $VBoxContainer/ScrollContainer/ShopContainer
@onready var start_button = $VBoxContainer/StartButton

var module_costs = {
	"Miner": {"unlock": 0, "upgrade": 50},
	"Conveyor": {"unlock": 0, "upgrade": 20},
	"Processor": {"unlock": 0, "upgrade": 50},
	"Weapon": {"unlock": 0, "upgrade": 100},
	"Shotgun": {"unlock": 200, "upgrade": 150},
	"Sniper": {"unlock": 300, "upgrade": 200},
	"Flamethrower": {"unlock": 250, "upgrade": 150},
	"Tesla": {"unlock": 400, "upgrade": 250},
	"Splitter": {"unlock": 100, "upgrade": 50},
	"Modifier": {"unlock": 150, "upgrade": 100}
}

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	update_ui()

func update_ui():
	if SaveManager:
		scrap_label.text = "Scrap: " + str(SaveManager.save_data["total_scrap"])

	# Clear shop container
	for child in shop_container.get_children():
		child.queue_free()

	# Populate shop
	for m_name in module_costs.keys():
		var hbox = HBoxContainer.new()

		var name_lbl = Label.new()

		var action_btn = Button.new()
		var is_unlocked = SaveManager.is_module_unlocked(m_name)
		var lvl = SaveManager.get_module_level(m_name)

		if not is_unlocked:
			name_lbl.text = m_name + " (Locked)"
			var cost = module_costs[m_name]["unlock"]
			action_btn.text = "Unlock (" + str(cost) + ")"
			action_btn.disabled = (SaveManager.save_data["total_scrap"] < cost)
			action_btn.pressed.connect(func():
				if SaveManager.unlock_module(m_name, cost):
					update_ui()
			)
		else:
			name_lbl.text = m_name + " (Lvl " + str(lvl) + ")"
			var up_cost = module_costs[m_name]["upgrade"] * lvl
			action_btn.text = "Upgrade (" + str(up_cost) + ")"
			action_btn.disabled = (SaveManager.save_data["total_scrap"] < up_cost)
			action_btn.pressed.connect(func():
				if SaveManager.upgrade_module(m_name, up_cost):
					update_ui()
			)

		hbox.add_child(name_lbl)
		hbox.add_child(action_btn)
		shop_container.add_child(hbox)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
