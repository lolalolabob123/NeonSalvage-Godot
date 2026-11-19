extends Node

signal banked_salvage_changed(total: int)

const SAVE_PATH: String = "user://neon_salvage_progress.cfg"
const HULL_REINFORCEMENT_COST: int = 10
const HULL_REINFORCEMENT_ID: StringName = &"hull_reinforcement"
const HULL_REINFORCEMENT_II_ID: StringName = &"hull_reinforcement_ii"
const EMERGENCY_PATCH_ID: StringName = &"emergency_patch"
const SHIELD_GENERATOR_ID: StringName = &"shield_generator"
const EMP_EMITTER_ID: StringName = &"emp_emitter"

const GEAR := {
	SHIELD_GENERATOR_ID: {
		"display_name": "Shield Generator",
		"save_key": "shield_generator",
	},
	EMP_EMITTER_ID: {
		"display_name": "EMP Emitter",
		"save_key": "emp_emitter",
	},
}

const SKILLS := {
	HULL_REINFORCEMENT_ID: {
		"display_name": "Hull reinforcement 1",
		"cost": HULL_REINFORCEMENT_COST,
		"prerequisites": [],
		"save_key": "hull_reinforced",
	},
	HULL_REINFORCEMENT_II_ID: {
		"display_name": "Hull Reinforcement 2",
		"cost": 20,
		"prerequisites": [HULL_REINFORCEMENT_ID],
		"save_key": "hull_reinforcement_ii",
	},
	EMERGENCY_PATCH_ID: {
		"display_name": "Emergency Patch",
		"cost": 20,
		"prerequisites": [HULL_REINFORCEMENT_ID],
		"save_key": "emergency_patch",
	},
}

var banked_salvage: int = 0
var storage_available: bool = true
var save_data: ConfigFile = ConfigFile.new()
var hull_reinforced: bool = false
var selected_primary_weapon: WeaponDefinition = null
var selected_system: StringName = &""

func _ready() -> void:
	var error := save_data.load(SAVE_PATH)

	# A new player doesn't have a save file yet.
	if error == ERR_FILE_NOT_FOUND:
		return

	if error != OK:
		storage_available = false
		push_error("Could not load saved progress: %s" % error_string(error))
		return

	var saved_total: Variant = save_data.get_value(
		"progress", "banked_salvage", 0
	)

	if typeof(saved_total) != TYPE_INT:
		storage_available = false
		push_error("Saved salvage balance is invalid.")
		return

	if saved_total < 0:
		storage_available = false
		push_error("Saved salvage balance is negative.")
		return

	banked_salvage = int(saved_total)
	
	var saved_upgrade: Variant = save_data.get_value(
		"upgrades", "hull_reinforced", false
	)
	
	if typeof(saved_upgrade) != TYPE_BOOL:
		storage_available = false
		push_error("Saved hull upgrade is invalid.")
		return
	
	hull_reinforced = bool(saved_upgrade)

func owns_gear(gear_id: StringName) -> bool:
	var gear: Dictionary = GEAR.get(gear_id, {})
	if gear.is_empty():
		return false
	
	var save_key: String = gear["save_key"]
	return save_data.get_value("gear", save_key, false) == true

func owns_shield_generator() -> bool:
	return owns_gear(SHIELD_GENERATOR_ID)

func bank_salvage(amount: int, secure_shield: bool = false) -> bool:
	var recovered_gear: Array[StringName] = []

	if secure_shield:
		recovered_gear.append(SHIELD_GENERATOR_ID)

	return bank_extraction(amount, recovered_gear)


func bank_extraction(
	amount: int,
	recovered_gear: Array[StringName]
) -> bool:
	if not storage_available or amount < 0:
		return false

	# Validate everything before changing the save.
	for gear_id in recovered_gear:
		if not GEAR.has(gear_id):
			push_error("Unknown recovered gear: %s" % gear_id)
			return false

	var previous_ownership: Dictionary = {}

	for gear_id in recovered_gear:
		var gear: Dictionary = GEAR[gear_id]
		var save_key: String = gear["save_key"]
		previous_ownership[save_key] = save_data.get_value(
			"gear", save_key, false
		)

	var new_total := banked_salvage + amount
	save_data.set_value("progress", "banked_salvage", new_total)

	for save_key in previous_ownership:
		save_data.set_value("gear", save_key, true)

	# Save once, after all equipment has been recorded.
	var error := save_data.save(SAVE_PATH)

	if error != OK:
		save_data.set_value(
			"progress", "banked_salvage", banked_salvage
		)

		for save_key in previous_ownership:
			save_data.set_value(
				"gear", save_key, previous_ownership[save_key]
			)

		push_error(
			"Could not save extraction: %s" % error_string(error)
		)
		return false

	banked_salvage = new_total
	banked_salvage_changed.emit(banked_salvage)
	return true

func purchase_hull_reinforcement() -> bool:
	return purchase_skill(HULL_REINFORCEMENT_ID)

func has_skill(skill_id: StringName) -> bool:
	var skill: Dictionary = SKILLS.get(skill_id, {})
	if skill.is_empty():
		return false
	
	var save_key: String = skill["save_key"]
	var owned: Variant = save_data.get_value("upgrades", save_key, false)
	return typeof(owned) == TYPE_BOOL and bool(owned)

func get_skill_cost(skill_id: StringName) -> int:
	var skill: Dictionary = SKILLS.get(skill_id, {})
	return int(skill.get("cost", -1))

func can_purchase_skill(skill_id: StringName) -> bool:
	var cost := get_skill_cost(skill_id)
	if not storage_available or cost < 0 or has_skill(skill_id):
		return false
	if banked_salvage < cost:
		return false
	
	for prerequisite in SKILLS[skill_id]["prerequisites"]:
		if not has_skill(prerequisite):
			return false
	
	return true

func purchase_skill(skill_id: StringName) -> bool:
	if not can_purchase_skill(skill_id):
		return false
	
	var skill: Dictionary = SKILLS[skill_id]
	var save_key: String = skill["save_key"]
	var new_total := banked_salvage - get_skill_cost(skill_id)
	var previous_ownership: Variant = save_data.get_value(
		"upgrades", save_key, false
	)
	
	save_data.set_value("progress", "banked_salvage", new_total)
	save_data.set_value("upgrades", save_key, true)
	
	var error := save_data.save(SAVE_PATH)
	if error != OK:
		save_data.set_value("progress", "banked_salvage", banked_salvage)
		save_data.set_value("upgrades", save_key, previous_ownership)
		push_error("Could not save skill purchase: %s" % error_string(error))
		return false
	
	banked_salvage = new_total
	hull_reinforced = has_skill(HULL_REINFORCEMENT_ID)
	banked_salvage_changed.emit(banked_salvage)
	return true

func reset_skills_for_testing() -> bool:
	if not OS.is_debug_build() or not storage_available:
		return false

	var owned_save_keys: Array[String] = []
	var refund := 0

	for skill_id in SKILLS:
		if has_skill(skill_id):
			var skill: Dictionary = SKILLS[skill_id]
			owned_save_keys.append(skill["save_key"])
			refund += get_skill_cost(skill_id)

	if owned_save_keys.is_empty():
		return true

	var new_total := banked_salvage + refund
	for save_key in owned_save_keys:
		save_data.set_value("upgrades", save_key, false)
	save_data.set_value("progress", "banked_salvage", new_total)

	var error := save_data.save(SAVE_PATH)
	if error != OK:
		for save_key in owned_save_keys:
			save_data.set_value("upgrades", save_key, true)
		save_data.set_value("progress", "banked_salvage", banked_salvage)
		push_error("Could not reset skills: %s" % error_string(error))
		return false

	banked_salvage = new_total
	hull_reinforced = false
	banked_salvage_changed.emit(banked_salvage)
	return true
