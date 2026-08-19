class_name GridManager
extends Node2D

var grid_size: Vector2i = Vector2i(7, 9)
var cell_size: int = 64

# Dictionary to map Vector2i grid coordinates to Module Nodes
var grid: Dictionary = {}

func _ready():
	print("GridManager initialized. Size: ", grid_size)

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

	return true

## Removes a module from the specified grid position
func remove_module(grid_pos: Vector2i):
	if grid.has(grid_pos):
		var module = grid[grid_pos]
		grid.erase(grid_pos)
		module.queue_free()

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
			target_building.receive_payload(payload)
	else:
		# Nowhere to go, payload is lost or clogs up.
		# For now, it just disappears.
		pass
