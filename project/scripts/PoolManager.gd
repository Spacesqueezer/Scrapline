class_name PoolManager
extends Node

var enemy_pool: Array[Enemy] = []
var projectile_pool: Array[Projectile] = []

var enemy_scene: PackedScene
var projectile_scene: PackedScene

func _ready():
	print("PoolManager initialized.")

func register_scenes(e_scene: PackedScene, p_scene: PackedScene):
	enemy_scene = e_scene
	projectile_scene = p_scene

func get_enemy() -> Enemy:
	for e in enemy_pool:
		if not e.is_active:
			return e

	var new_enemy: Enemy
	if enemy_scene:
		new_enemy = enemy_scene.instantiate() as Enemy
	else:
		# Fallback to direct instantiation for prototyping
		new_enemy = Enemy.new()

	add_child(new_enemy)
	enemy_pool.append(new_enemy)
	new_enemy.hide()
	new_enemy.is_active = false
	return new_enemy

func get_projectile() -> Projectile:
	for p in projectile_pool:
		if not p.is_active:
			return p

	var new_proj: Projectile
	if projectile_scene:
		new_proj = projectile_scene.instantiate() as Projectile
	else:
		# Fallback to direct instantiation for prototyping
		new_proj = Projectile.new()

	add_child(new_proj)
	projectile_pool.append(new_proj)
	new_proj.hide()
	new_proj.is_active = false
	return new_proj
