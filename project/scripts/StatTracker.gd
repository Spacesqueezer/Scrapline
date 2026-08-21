extends Node

var run_stats = {
	"waves_completed": 0,
	"energy_spent": 0,
	"buildings_placed": {},
	"damage_dealt": 0.0,
	"damage_taken_core": 0.0,
	"damage_taken_buildings": 0.0,
	"enemies_spawned": {"Basic": 0, "Swarm": 0, "Armored": 0, "Boss": 0},
	"enemies_killed": {"Basic": 0, "Swarm": 0, "Armored": 0, "Boss": 0},
	"resources_produced": {"RawMetal": 0, "Ammo": 0}
}

func start_run():
	run_stats = {
		"waves_completed": 0,
		"energy_spent": 0,
		"buildings_placed": {},
		"damage_dealt": 0.0,
		"damage_taken_core": 0.0,
		"damage_taken_buildings": 0.0,
		"enemies_spawned": {"Basic": 0, "Swarm": 0, "Armored": 0, "Boss": 0},
		"enemies_killed": {"Basic": 0, "Swarm": 0, "Armored": 0, "Boss": 0},
		"resources_produced": {"RawMetal": 0, "Ammo": 0}
	}

func track_building_placed(b_name: String, cost: int):
	run_stats["energy_spent"] += cost
	if not run_stats["buildings_placed"].has(b_name):
		run_stats["buildings_placed"][b_name] = 0
	run_stats["buildings_placed"][b_name] += 1

func track_damage_dealt(amount: float):
	run_stats["damage_dealt"] += amount

func track_damage_taken(amount: float, is_core: bool):
	if is_core:
		run_stats["damage_taken_core"] += amount
	else:
		run_stats["damage_taken_buildings"] += amount

func track_enemy_spawn(e_type: String):
	if run_stats["enemies_spawned"].has(e_type):
		run_stats["enemies_spawned"][e_type] += 1

func track_enemy_kill(e_type: String):
	if run_stats["enemies_killed"].has(e_type):
		run_stats["enemies_killed"][e_type] += 1

func track_resource_produced(res_type: String):
	if run_stats["resources_produced"].has(res_type):
		run_stats["resources_produced"][res_type] += 1

func update_wave(wave: int):
	run_stats["waves_completed"] = wave

func generate_report() -> String:
	var report = "=== SCRAPLINE RUN REPORT ===\n"
	report += "Waves Completed: " + str(run_stats["waves_completed"]) + "\n"
	report += "Energy Spent: " + str(run_stats["energy_spent"]) + "\n"
	report += "Damage Dealt: " + str(int(run_stats["damage_dealt"])) + "\n"
	report += "Core Damage Taken: " + str(int(run_stats["damage_taken_core"])) + "\n"
	report += "Buildings Damage Taken: " + str(int(run_stats["damage_taken_buildings"])) + "\n"

	report += "\n--- BUILDINGS PLACED ---\n"
	for b in run_stats["buildings_placed"].keys():
		report += b + ": " + str(run_stats["buildings_placed"][b]) + "\n"

	report += "\n--- RESOURCES PRODUCED ---\n"
	report += "RawMetal: " + str(run_stats["resources_produced"]["RawMetal"]) + "\n"
	report += "Ammo: " + str(run_stats["resources_produced"]["Ammo"]) + "\n"

	report += "\n--- ENEMIES ---\n"
	for e in run_stats["enemies_spawned"].keys():
		var spawned = run_stats["enemies_spawned"][e]
		var killed = run_stats["enemies_killed"][e]
		report += e + " (Spawned: " + str(spawned) + ", Killed: " + str(killed) + ")\n"

	report += "============================"
	return report
