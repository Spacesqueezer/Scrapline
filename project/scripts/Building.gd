class_name Building
extends Node2D

@export var data: ModuleData
var grid_position: Vector2i
var facing_direction: Vector2i = Vector2i.RIGHT # UP, DOWN, LEFT, RIGHT

# For receiving payload
signal on_payload_received(payload: Payload)
# For outputting payload
signal on_payload_output(payload: Payload, direction: Vector2i)

func _ready():
	pass

func setup(p_data: ModuleData, p_grid_pos: Vector2i):
	data = p_data
	grid_position = p_grid_pos

func receive_payload(payload: Payload):
	# Base class logic. Override in subclasses.
	on_payload_received.emit(payload)

func process_building(delta: float):
	pass

func rotate_building(dir: Vector2i):
	facing_direction = dir
	# Update visual rotation based on facing direction
	if dir == Vector2i.RIGHT:
		rotation_degrees = 0
	elif dir == Vector2i.DOWN:
		rotation_degrees = 90
	elif dir == Vector2i.LEFT:
		rotation_degrees = 180
	elif dir == Vector2i.UP:
		rotation_degrees = -90
