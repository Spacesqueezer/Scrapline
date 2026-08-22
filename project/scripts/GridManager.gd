class_name GridManager
extends Node2D

var grid_size: Vector2i = Vector2i(7, 9)
var cell_size: int = 100

# Dictionary to map Vector2i grid coordinates to Module Nodes
var grid: Dictionary = {}
# Array to store coordinates of Ore Veins
var ore_veins: Array[Vector2i] = []

var current_selected_building: String = ""
var can_build: bool = true

var core_building: CoreBuilding

@onready var pool_manager = get_node("/root/Main/PoolManager")
@onready var game_manager = get_node("/root/Main/GameManager")

func _ready():
	print("GridManager initialized. Size: ", grid_size)
	_generate_ore_veins()
	queue_redraw()
	# Размещаем Ядро на старте (посередине внизу)
	_place_core()

func _generate_ore_veins():
	ore_veins.clear()
	var vein_count = 5 # Количество жил на уровне
	# Исключаем нижний ряд (возле ядра)
	for i in range(vein_count):
		var rx = randi() % grid_size.x
		var ry = randi() % (grid_size.y - 2) # Выше нижних 2 рядов
		var pos = Vector2i(rx, ry)
		if pos not in ore_veins:
			ore_veins.append(pos)

func _place_core():
	core_building = CoreBuilding.new()
	var md = ModuleData.new()
	var core_pos = Vector2i(grid_size.x / 2, grid_size.y - 1)

	# Убедимся, что под ядром нет руды
	if core_pos in ore_veins:
		ore_veins.erase(core_pos)

	core_building.setup(md, core_pos)
	core_building.facing_direction = Vector2i.UP
	place_module(core_building.grid_position, core_building)

func set_selected_building(building_type: String):
	current_selected_building = building_type
	print("Selected building to build: ", current_selected_building)

func _unhandled_input(event):
	if not can_build:
		return

	# In Godot 4, it's safer to check for both mouse clicks and screen touches
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		# Use local mouse position to account for the GridManager's node offset on screen
		var local_pos = get_local_mouse_position()
		var grid_pos = world_to_grid(local_pos)

		print("Input at local_pos: ", local_pos, " | grid_pos: ", grid_pos, " | Valid: ", is_valid_pos(grid_pos))

		if is_valid_pos(grid_pos) and current_selected_building != "":
			if current_selected_building == "Delete":
				remove_module(grid_pos)
			elif current_selected_building == "Rotate":
				rotate_module(grid_pos)
			else:
				attempt_build(grid_pos)

func rotate_module(grid_pos: Vector2i):
	if grid.has(grid_pos):
		var module = grid[grid_pos] as Building
		if module:
			module.rotate_building()

func get_building_cost(type: String) -> int:
	match type:
		"Conveyor": return 2
		"Miner": return 15
		"Processor": return 20
		"Modifier": return 25
		"Weapon", "Shotgun", "Flamethrower", "Tesla", "Sniper": return 30
		"Splitter": return 10
	return 10

func attempt_build(grid_pos: Vector2i):
	if grid.has(grid_pos):
		print("Cell occupied!")
		return

	var is_ore_vein = grid_pos in ore_veins

	if current_selected_building == "Miner" and not is_ore_vein:
		print("Miner must be placed on an Ore Vein!")
		# TODO: Показать визуальную ошибку (всплывающий текст)
		return
	elif current_selected_building != "Miner" and is_ore_vein:
		print("Cannot place this building on an Ore Vein!")
		return

	var cost = get_building_cost(current_selected_building)

	if game_manager and game_manager.current_energy < cost:
		print("Not enough energy!")
		return

	var new_building: Building = null

	match current_selected_building:
		"Miner":
			new_building = Miner.new()
			var md = ModuleData.new()
			new_building.setup(md, grid_pos)
			new_building.facing_direction = Vector2i.UP
		"Conveyor":
			new_building = ConveyorBuilding.new()
			var md = ModuleData.new()
			var lvl = SaveManager.get_module_level("Conveyor") if SaveManager else 1
			new_building.setup(md, grid_pos)
			new_building.processing_time = 0.1 / (1.0 + (lvl - 1) * 0.1) # Ускорение передачи
			new_building.facing_direction = Vector2i.UP
		"Processor":
			new_building = ProcessorBuilding.new()
			var md = ModuleData.new()
			var lvl = SaveManager.get_module_level("Processor") if SaveManager else 1
			new_building.setup(md, grid_pos)
			new_building.processing_time = 0.5 / (1.0 + (lvl - 1) * 0.1) # Ускорение переработки
			new_building.facing_direction = Vector2i.UP
		"Modifier":
			new_building = ModifierBuilding.new()
			var mod_data = ModifierData.new()
			var tags: Array[String] = ["Explosive", "Fire"]
			mod_data.tags_to_add = tags
			mod_data.stat_multipliers = {"damage": 1.5}
			new_building.modifier_data = mod_data
			new_building.setup(mod_data, grid_pos)
			new_building.facing_direction = Vector2i.UP
		"Weapon":
			new_building = WeaponBuilding.new()
			var w_data = WeaponData.new()
			var lvl = SaveManager.get_module_level("Weapon") if SaveManager else 1
			w_data.fire_rate = 2.0 * (1.0 + (lvl - 1) * 0.1)
			w_data.range = 500.0
			new_building.setup_weapon(w_data, grid_pos)
			new_building.facing_direction = Vector2i.UP
			new_building.on_fire.connect(_on_weapon_fire)
		"Shotgun":
			new_building = WeaponBuilding.new()
			var w_data = WeaponData.new()
			var lvl = SaveManager.get_module_level("Shotgun") if SaveManager else 1
			w_data.fire_rate = 1.0
			w_data.range = 250.0
			w_data.firing_arc = 30.0
			w_data.projectiles_per_shot = 3 + (lvl - 1)
			new_building.setup_weapon(w_data, grid_pos)
			new_building.facing_direction = Vector2i.UP
			new_building.on_fire.connect(_on_weapon_fire)
		"Sniper":
			new_building = SniperBuilding.new()
			var w_data = WeaponData.new()
			var lvl = SaveManager.get_module_level("Sniper") if SaveManager else 1
			w_data.fire_rate = 0.5
			w_data.range = 800.0
			w_data.base_damage = 50.0 * (1.0 + (lvl - 1) * 0.2)
			new_building.setup_weapon(w_data, grid_pos)
			new_building.facing_direction = Vector2i.UP
			new_building.on_fire.connect(_on_weapon_fire)
		"Flamethrower":
			new_building = FlamethrowerBuilding.new()
			var w_data = WeaponData.new()
			var lvl = SaveManager.get_module_level("Flamethrower") if SaveManager else 1
			w_data.fire_rate = 5.0
			w_data.range = 200.0
			w_data.firing_arc = 60.0
			w_data.base_damage = 5.0 * (1.0 + (lvl - 1) * 0.15)
			new_building.setup_weapon(w_data, grid_pos)
			new_building.facing_direction = Vector2i.UP
			new_building.on_fire.connect(_on_weapon_fire)
		"Tesla":
			new_building = TeslaBuilding.new()
			var w_data = WeaponData.new()
			var lvl = SaveManager.get_module_level("Tesla") if SaveManager else 1
			w_data.fire_rate = 1.5
			w_data.range = 350.0
			w_data.base_damage = 15.0 * (1.0 + (lvl - 1) * 0.2)
			new_building.setup_weapon(w_data, grid_pos)
			new_building.facing_direction = Vector2i.UP
			new_building.on_fire.connect(_on_weapon_fire)
		"Splitter":
			new_building = SplitterBuilding.new()
			var md = ModuleData.new()
			new_building.setup(md, grid_pos)
			new_building.facing_direction = Vector2i.UP

	if new_building:
		if game_manager:
			game_manager.current_energy -= cost
			game_manager.energy_changed.emit(game_manager.current_energy, game_manager.max_energy)
		if StatTracker:
			StatTracker.track_building_placed(current_selected_building, cost)
		place_module(grid_pos, new_building)

func _draw():
	# Отрисовываем рудные жилы (Ore Veins)
	for vein in ore_veins:
		var center = grid_to_world(vein)
		# Рисуем пятно руды (коричнево-серое)
		draw_circle(center, cell_size * 0.4, Color(0.4, 0.35, 0.3, 0.8))
		draw_circle(center + Vector2(10, 10), cell_size * 0.2, Color(0.3, 0.25, 0.2, 0.8))
		draw_circle(center + Vector2(-15, -5), cell_size * 0.15, Color(0.5, 0.45, 0.4, 0.8))

	# Отрисовываем сетку
	for x in range(grid_size.x + 1):
		draw_line(Vector2(x * cell_size, 0), Vector2(x * cell_size, grid_size.y * cell_size), Color(1.0, 1.0, 1.0, 0.3), 3.0)
	for y in range(grid_size.y + 1):
		draw_line(Vector2(0, y * cell_size), Vector2(grid_size.x * cell_size, y * cell_size), Color(1.0, 1.0, 1.0, 0.3), 3.0)

## Converts world position to grid coordinates
func world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / cell_size), floor(pos.y / cell_size))

## Converts grid coordinates to world position (center of the cell)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * cell_size + cell_size / 2.0, grid_pos.y * cell_size + cell_size / 2.0)

## Checks if a grid position is within the bounds of the grid
func is_valid_pos(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < grid_size.x and grid_pos.y >= 0 and grid_pos.y < grid_size.y

## Places a module at the specified grid position
func place_module(grid_pos: Vector2i, module_node: Node2D) -> bool:
	if not is_valid_pos(grid_pos):
		return false
	if grid.has(grid_pos):
		return false # Cell is occupied

	grid[grid_pos] = module_node
	module_node.position = grid_to_world(grid_pos)
	add_child(module_node)

	if module_node is Building:
		module_node.grid_position = grid_pos
		connect_building(module_node)
		# Синхронизируем логическое направление со вращением спрайта при постройке
		module_node.rotate_building(module_node.facing_direction)

	return true

func _on_weapon_fire(payload: Payload, start_pos: Vector2, target: Node2D, hit_point: Vector2):
	var proj = null
	if pool_manager:
		proj = pool_manager.get_projectile()
	else:
		proj = Projectile.new()
		add_child(proj)

	if proj:
		# Вызов setup теперь учитывает hit_point. Оружие уже вычислило,
		# попало оно во врага или пуля летит в пустоту.
		proj.setup(start_pos, target, payload, hit_point)

## Removes a module from the specified grid position
func remove_module(grid_pos: Vector2i):
	if grid.has(grid_pos):
		var module = grid[grid_pos]
		if module is CoreBuilding:
			print("Cannot delete Core Building!")
			return

		# Восстанавливаем энергию
		if module is Building:
			var cost = 10
			if current_selected_building != "":
				# Попытка получить цену здания, хотя мы уже не знаем тип при удалении точно без проверки класса,
				# для прототипа сойдет. Но лучше сделать проверку.
				if module is Miner: cost = get_building_cost("Miner")
				elif module is ConveyorBuilding: cost = get_building_cost("Conveyor")
				elif module is ProcessorBuilding: cost = get_building_cost("Processor")
				elif module is ModifierBuilding: cost = get_building_cost("Modifier")
				elif module is WeaponBuilding: cost = get_building_cost("Weapon")
				elif module is SplitterBuilding: cost = get_building_cost("Splitter")

			if game_manager:
				game_manager.current_energy += cost
				game_manager.energy_changed.emit(game_manager.current_energy, game_manager.max_energy)

		grid.erase(grid_pos)
		module.queue_free()

func clear_grid():
	var keys = grid.keys()
	for key in keys:
		if grid[key] is CoreBuilding:
			continue
		remove_module(key)

## Gets the module at a specific position, returns null if empty
func get_module_at(grid_pos: Vector2i) -> Node2D:
	if grid.has(grid_pos):
		return grid[grid_pos]
	return null

## Connects building output signals to the grid logic
func connect_building(building: Building):
	if not building.on_payload_output.is_connected(_on_building_output):
		building.on_payload_output.connect(_on_building_output.bind(building))

func _on_building_output(payload: Payload, direction: Vector2i, source_building: Building):
	# Calculate target grid position
	var target_pos = source_building.grid_position + direction

	if is_valid_pos(target_pos) and grid.has(target_pos):
		var target_building = grid[target_pos] as Building
		if target_building:
			# Передаем payload в can_receive_payload, чтобы здание могло отфильтровать тип ресурса
			if not target_building.has_method("can_receive_payload") or target_building.can_receive_payload(payload):
				visualize_payload_transfer(payload, source_building.global_position, target_building.global_position)
				target_building.receive_payload(payload)
			else:
				# Здание забито или ресурс не подходит, ресурс теряется
				pass
	else:
		# Nowhere to go, payload is lost
		pass

func visualize_payload_transfer(payload: Payload, start: Vector2, end: Vector2):
	var vis = PayloadVisualizer.new()
	add_child(vis)
	vis.setup(payload, start, end)
