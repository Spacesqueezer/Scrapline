class_name Payload
extends RefCounted

var base_type: String = "Scrap"
var base_damage: float = 10.0
var tags: Array[String] = []

func _init(type: String = "Scrap", dmg: float = 10.0):
	base_type = type
	base_damage = dmg

func apply_modifier(modifier: ModifierData):
	for tag in modifier.tags_to_add:
		if not tags.has(tag):
			tags.append(tag)

	if modifier.stat_multipliers.has("damage"):
		base_damage *= modifier.stat_multipliers["damage"]
