class_name WeaponData
extends ModuleData

@export var fire_rate: float = 1.0 # Shots per second
@export var base_damage: float = 10.0
@export var range: float = 300.0
@export var firing_arc: float = 360.0 # Сектор обстрела в градусах (360 = все стороны, 90 = конус перед пушкой)
@export var projectiles_per_shot: int = 1 # Сколько снарядов вылетает за 1 выстрел (например, для дробовика)
@export var projectile_scene: PackedScene
