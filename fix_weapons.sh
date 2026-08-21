#!/bin/bash
cat << 'INNER_EOF' > project/scripts/SniperBuilding.gd
class_name SniperBuilding
extends WeaponBuilding

func _init():
	base_texture_path = "res://assets/sniper.svg"
	# Fallback texture if sniper.svg isn't present

func setup_weapon(w_data: WeaponData, p_grid_pos: Vector2i):
	super.setup_weapon(w_data, p_grid_pos)
	if sprite and ResourceLoader.exists(base_texture_path):
		sprite.texture = load(base_texture_path)
INNER_EOF

cat << 'INNER_EOF' > project/scripts/FlamethrowerBuilding.gd
class_name FlamethrowerBuilding
extends WeaponBuilding

func _init():
	base_texture_path = "res://assets/flamethrower.svg"

func setup_weapon(w_data: WeaponData, p_grid_pos: Vector2i):
	super.setup_weapon(w_data, p_grid_pos)
	if sprite and ResourceLoader.exists(base_texture_path):
		sprite.texture = load(base_texture_path)
INNER_EOF

cat << 'INNER_EOF' > project/scripts/TeslaBuilding.gd
class_name TeslaBuilding
extends WeaponBuilding

func _init():
	base_texture_path = "res://assets/tesla.svg"

func setup_weapon(w_data: WeaponData, p_grid_pos: Vector2i):
	super.setup_weapon(w_data, p_grid_pos)
	if sprite and ResourceLoader.exists(base_texture_path):
		sprite.texture = load(base_texture_path)
INNER_EOF

# Add buttons for new weapons to BuildMenu.gd
sed -i '/_create_building_button("Shotgun")/a \\t_create_building_button("Sniper")\n\t_create_building_button("Flamethrower")\n\t_create_building_button("Tesla")' project/scripts/BuildMenu.gd

# Add placement logic to GridManager.gd
sed -i '/"Shotgun":/i \
		"Sniper":\
			new_building = SniperBuilding.new()\
			var w_data = WeaponData.new()\
			var lvl = SaveManager.get_module_level("Sniper") if SaveManager else 1\
			w_data.fire_rate = 0.5\
			w_data.range = 800.0\
			w_data.base_damage = 50.0 * (1.0 + (lvl - 1) * 0.2)\
			new_building.setup_weapon(w_data, grid_pos)\
			new_building.facing_direction = Vector2i.UP\
			new_building.on_fire.connect(_on_weapon_fire)\
		"Flamethrower":\
			new_building = FlamethrowerBuilding.new()\
			var w_data = WeaponData.new()\
			var lvl = SaveManager.get_module_level("Flamethrower") if SaveManager else 1\
			w_data.fire_rate = 5.0\
			w_data.range = 200.0\
			w_data.firing_arc = 60.0\
			w_data.base_damage = 5.0 * (1.0 + (lvl - 1) * 0.15)\
			new_building.setup_weapon(w_data, grid_pos)\
			new_building.facing_direction = Vector2i.UP\
			new_building.on_fire.connect(_on_weapon_fire)\
		"Tesla":\
			new_building = TeslaBuilding.new()\
			var w_data = WeaponData.new()\
			var lvl = SaveManager.get_module_level("Tesla") if SaveManager else 1\
			w_data.fire_rate = 1.5\
			w_data.range = 350.0\
			w_data.base_damage = 15.0 * (1.0 + (lvl - 1) * 0.2)\
			new_building.setup_weapon(w_data, grid_pos)\
			new_building.facing_direction = Vector2i.UP\
			new_building.on_fire.connect(_on_weapon_fire)' project/scripts/GridManager.gd

# Add new modules to MainMenu.gd module_costs
sed -i 's/"Shotgun": {"unlock": 200, "upgrade": 150},/"Shotgun": {"unlock": 200, "upgrade": 150},\n\t"Sniper": {"unlock": 300, "upgrade": 200},\n\t"Flamethrower": {"unlock": 250, "upgrade": 150},\n\t"Tesla": {"unlock": 400, "upgrade": 250},/g' project/scripts/MainMenu.gd
