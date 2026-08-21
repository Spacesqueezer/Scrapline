class_name Miner
extends Building

@export var produce_time: float = 1.0
var timer: float = 0.0
var active: bool = false

func _init():
	base_texture_path = "res://assets/miner.svg"

func _ready():
	super._ready()
	active = true

func _process(delta):
	if not active or not is_combat_active():
		return

	timer += delta
	if timer >= produce_time:
		timer = 0.0
		produce()

func produce():
	# Майнер добывает сырой металл, который еще нужно переработать
	var p = Payload.new("RawMetal", 10.0)
	if StatTracker:
		StatTracker.track_resource_produced("RawMetal")
	# Emit out in the facing direction
	on_payload_output.emit(p, facing_direction)

func _draw():
	super._draw()
	# Рисуем стрелку направления выдачи
	var dir_vec = Vector2(facing_direction)
	var arrow_len = 35.0
	var arrow_end = dir_vec * arrow_len
	var color = Color(0.2, 1.0, 0.2, 0.8) # Зеленая стрелка

	# Линия стрелки
	draw_line(Vector2.ZERO, arrow_end, color, 4.0)

	# Усики стрелки
	var angle = dir_vec.angle()
	var left_wing = arrow_end - Vector2.from_angle(angle - PI/6) * 10.0
	var right_wing = arrow_end - Vector2.from_angle(angle + PI/6) * 10.0
	draw_line(arrow_end, left_wing, color, 4.0)
	draw_line(arrow_end, right_wing, color, 4.0)
