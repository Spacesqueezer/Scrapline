class_name BossEnemy
extends Enemy

var emp_cooldown: float = 5.0
var current_emp_timer: float = 0.0

func _init():
	hp = 500.0
	max_hp = 500.0
	speed = 20.0
	attack_damage = 50.0
	attack_range = 80.0

func _ready():
	super._ready()
	if sprite:
		# Сделаем босса больше и зададим цвет или текстуру
		sprite.scale = Vector2(1.5, 1.5)
		sprite.modulate = Color(0.8, 0.2, 1.0) # Фиолетовый оттенок для отличия
		# Пока используем текстуру бронированного врага
		sprite.texture = load("res://assets/enemy_armored.svg")

func _process(delta):
	super._process(delta)

	if not is_active:
		return

	current_emp_timer += delta
	if current_emp_timer >= emp_cooldown:
		current_emp_timer = 0.0
		cast_emp()

func cast_emp():
	var gm = get_node_or_null("/root/Main/World2D/GridManager")
	if not gm:
		return

	var valid_targets: Array[Building] = []
	for key in gm.grid:
		var b = gm.grid[key]
		if b is Building and not b.is_destroyed and b != gm.core_building:
			valid_targets.append(b)

	valid_targets.shuffle()

	var targets_to_emp = min(3, valid_targets.size())
	for i in range(targets_to_emp):
		var target = valid_targets[i]
		target.apply_emp(5.0)

		# Визуальный эффект каста от босса к зданию
		_show_emp_tracer(target.global_position)

func _show_emp_tracer(target_pos: Vector2):
	var line = Line2D.new()
	line.add_point(global_position)
	line.add_point(target_pos)
	line.default_color = Color(1.0, 1.0, 0.0, 0.8) # Желтая молния
	line.width = 4.0
	get_tree().current_scene.add_child(line)

	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func(): line.queue_free())
