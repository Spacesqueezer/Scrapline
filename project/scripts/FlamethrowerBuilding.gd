class_name FlamethrowerBuilding
extends WeaponBuilding

func _init():
	base_texture_path = "res://assets/flamethrower.svg"

func setup_weapon(w_data: WeaponData, p_grid_pos: Vector2i):
	super.setup_weapon(w_data, p_grid_pos)
	if sprite and ResourceLoader.exists(base_texture_path):
		sprite.texture = load(base_texture_path)
