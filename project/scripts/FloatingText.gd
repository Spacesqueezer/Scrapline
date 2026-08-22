class_name FloatingText
extends Node2D

var text: String = ""
var color: Color = Color.WHITE
var speed: float = 50.0
var lifetime: float = 1.0
var t: float = 0.0

func setup(p_text: String, start_pos: Vector2, p_color: Color = Color.WHITE):
	text = p_text
	global_position = start_pos
	color = p_color

	# Небольшой случайный разброс позиции
	global_position.x += randf_range(-15.0, 15.0)
	global_position.y += randf_range(-15.0, 15.0)

	show()

func _process(delta):
	t += delta
	global_position.y -= speed * delta

	queue_redraw()

	if t >= lifetime:
		queue_free()

func _draw():
	# Отрисовка текста
	# Поскольку в прототипе мы не грузим шрифты, используем дефолтный шрифт
	# Уменьшаем альфу со временем
	var alpha = 1.0 - (t / lifetime)
	var draw_color = color
	draw_color.a = alpha

	draw_string(ThemeDB.fallback_font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, draw_color)
