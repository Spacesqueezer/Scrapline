class_name ModifierData
extends ModuleData

## Array of string tags like "Fire", "Explosive", "Piercing"
@export var tags_to_add: Array[String] = []

## Dictionary for stat multiplication, e.g. {"damage": 1.5, "speed": 0.8}
@export var stat_multipliers: Dictionary = {}
