extends Node

signal banked_salvage_changed(total: int)
signal loadout_changed

const SAVE_PATH: String = "user://neon_salvage_progress.cfg"
const HULL_REINFORCEMENT_COST: int = 10
const HULL_REINFORCEMENT_ID: StringName = &"hull_reinforcement"
const HULL_REINFORCEMENT_II_ID: StringName = &"hull_reinforcement_ii"
const EMERGENCY_PATCH_ID: StringName = &"emergency_patch"
const SHIELD_GENERATOR_ID: StringName = &"shield_generator"
const EMP_EMITTER_ID: StringName = &"emp_emitter"
const STANDARD_CHASSIS_ID: StringName = &"standard_chassis"
const LIGHT_CHASSIS_ID: StringName = &"light_chassis"
const HEAVY_CHASSIS_ID: StringName = &"heavy_chassis"
const STANDARD_THRUSTERS_ID: StringName = &"standard_thrusters"
const BURST_THRUSTERS_ID: StringName = &"burst_thrusters"
const RAPID_CYCLE_THRUSTERS_ID: StringName = &"rapid_cycle_thrusters"

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

const EQUIPMENT := {
	&"carbine": preload(
		"res://resources/equipment/CarbineEquipment.tres"
	),
	&"shotgun": preload(
		"res://resources/equipment/ShotgunEquipment.tres"
	),
	SHIELD_GENERATOR_ID: preload(
		"res://resources/equipment/ShieldGeneratorEquipment.tres"
	),
	EMP_EMITTER_ID: preload(
		"res://resources/equipment/EMPEmitterEquipment.tres"
	),
	STANDARD_CHASSIS_ID: preload(
		"res://resources/equipment/StandardChassis.tres"
	),
	LIGHT_CHASSIS_ID: preload(
		"res://resources/equipment/LightChassis.tres"
	),
	HEAVY_CHASSIS_ID: preload(
		"res://resources/equipment/HeavyChassis.tres"
	),
	STANDARD_THRUSTERS_ID: preload(
		"res://resources/equipment/StandardThrusters.tres"
	),
	BURST_THRUSTERS_ID: preload(
		"res://resources/equipment/BurstThrusters.tres"
	),
	RAPID_CYCLE_THRUSTERS_ID: preload(
		"res://resources/equipment/RapidCycleThrusters.tres"
	),
}

const STARTER_EQUIPMENT_IDS: Array[StringName] = [
	&"carbine",
	&"shotgun",
	STANDARD_CHASSIS_ID,
	STANDARD_THRUSTERS_ID,

	# Temporarily available for equipment testing.
	LIGHT_CHASSIS_ID,
	HEAVY_CHASSIS_ID,
	BURST_THRUSTERS_ID,
	RAPID_CYCLE_THRUSTERS_ID,
]

var banked_salvage: int = 0
var storage_available: bool = true
var save_data: ConfigFile = ConfigFile.new()
var hull_reinforced: bool = false
var selected_primary_weapon: WeaponDefinition = null
var selected_system: StringName = &""
var selected_mission_index: int = 0
var selected_chassis_id: StringName = STANDARD_CHASSIS_ID
var selected_thrusters_id: StringName = STANDARD_THRUSTERS_ID

func _ready() -> void:
	var error := save_data.load(SAVE_PATH)

	# A new player doesn't have a save file yet.
	if error == ERR_FILE_NOT_FOUND:
		_restore_loadout()
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
	_restore_loadout()

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

func get_equipment(
	equipment_id: StringName
) -> EquipmentDefinition:
	return EQUIPMENT.get(equipment_id) as EquipmentDefinition

func owns_equipment(equipment_id: StringName) -> bool:
	if not EQUIPMENT.has(equipment_id):
		return false
	
	if STARTER_EQUIPMENT_IDS.has(equipment_id):
		return true
	
	return owns_gear(equipment_id)

func get_owned_equipment_for_slot(
	slot: EquipmentDefinition.Slot
) -> Array[EquipmentDefinition]:
	var result: Array[EquipmentDefinition] = []
	
	for equipment_id in EQUIPMENT:
		var equipment := get_equipment(equipment_id)
		
		if equipment == null:
			continue
		
		if equipment.slot != slot:
			continue
		
		if owns_equipment(equipment_id):
			result.append(equipment)
	
	return result

func can_equip_equipment(
	equipment_id: StringName,
	target_slot: EquipmentDefinition.Slot
) -> bool:
	# These are thw two slots currently implemnted.
	if (
		target_slot != EquipmentDefinition.Slot.PRIMARY_WEAPON
		and target_slot != EquipmentDefinition.Slot.ACTIVE_SYSTEM
		and target_slot != EquipmentDefinition.Slot.CHASSIS
		and target_slot != EquipmentDefinition.Slot.THRUSTERS
	):
		return false
	
	# An empty ID means unequip the active system.
	if equipment_id == &"":
		return target_slot == EquipmentDefinition.Slot.ACTIVE_SYSTEM
	
	var equipment := get_equipment(equipment_id)
	
	if equipment == null:
		return false
	
	if equipment.equipment_id != equipment_id:
		return false
	
	if equipment.slot != target_slot:
		return false
	
	if not owns_equipment(equipment_id):
		return false
	
	if target_slot == EquipmentDefinition.Slot.PRIMARY_WEAPON:
		if equipment.weapon_definition == null:
			return false
	
	return true

func equip_equipment(
	equipment_id: StringName,
	target_slot: EquipmentDefinition.Slot
) -> bool:
	if not can_equip_equipment(equipment_id, target_slot):
		return false
	
	if not _save_equipment_choice(equipment_id, target_slot):
		return false

	match target_slot:
		EquipmentDefinition.Slot.PRIMARY_WEAPON:
			var equipment := get_equipment(equipment_id)

			if selected_primary_weapon == equipment.weapon_definition:
				return true

			selected_primary_weapon = equipment.weapon_definition

		EquipmentDefinition.Slot.ACTIVE_SYSTEM:
			if selected_system == equipment_id:
				return true

			selected_system = equipment_id

		EquipmentDefinition.Slot.CHASSIS:
			if selected_chassis_id == equipment_id:
				return true

			selected_chassis_id = equipment_id
		
		EquipmentDefinition.Slot.THRUSTERS:
			if selected_thrusters_id == equipment_id:
				return true
			
			selected_thrusters_id = equipment_id

		_:
			return false

	loadout_changed.emit()
	return true

func get_equipped_chassis() -> EquipmentDefinition:
	var chassis := get_equipment(selected_chassis_id)
	
	if (
		chassis != null
		and chassis.slot == EquipmentDefinition.Slot.CHASSIS
		and owns_equipment(selected_chassis_id)
	):
		return chassis
	
	return get_equipment(STANDARD_CHASSIS_ID)

func get_equipment_for_weapon(
	weapon: WeaponDefinition
) -> EquipmentDefinition:
	if weapon == null:
		return null

	for equipment_id in EQUIPMENT:
		var equipment := get_equipment(equipment_id)

		if equipment == null:
			continue

		if equipment.slot != EquipmentDefinition.Slot.PRIMARY_WEAPON:
			continue

		if equipment.weapon_definition == weapon:
			return equipment

	return null

func get_equipped_thrusters() -> EquipmentDefinition:
	var thrusters := get_equipment(selected_thrusters_id)
	
	if (
		thrusters != null
		and thrusters.slot == EquipmentDefinition.Slot.THRUSTERS
		and owns_equipment(selected_thrusters_id)
	):
		return thrusters
	
	return get_equipment(STANDARD_THRUSTERS_ID)

func _read_saved_equipment_id(
	save_key: String,
	fallback_id: StringName,
	target_slot: EquipmentDefinition.Slot
) -> StringName:
	var saved_value: Variant = save_data.get_value(
		"loadout",
		save_key,
		String(fallback_id)
	) 
	
	if (
		typeof(saved_value) != TYPE_STRING
		and typeof(saved_value) != TYPE_STRING_NAME
	):
		return fallback_id
	
	var equipment_id := StringName(saved_value)
	
	if can_equip_equipment(equipment_id, target_slot):
		return equipment_id
	
	return fallback_id

func _restore_loadout() -> void:
	var weapon_id := _read_saved_equipment_id(
		"primary_weapon",
		&"carbine",
		EquipmentDefinition.Slot.PRIMARY_WEAPON
	)
	
	selected_primary_weapon = get_equipment(
		weapon_id
	).weapon_definition
	
	selected_system = _read_saved_equipment_id(
		"active_system",
		&"",
		EquipmentDefinition.Slot.ACTIVE_SYSTEM
	)
	
	selected_chassis_id = _read_saved_equipment_id(
		"chassis",
		STANDARD_CHASSIS_ID,
		EquipmentDefinition.Slot.CHASSIS
	)
	
	selected_thrusters_id = _read_saved_equipment_id(
		"thrusters",
		STANDARD_THRUSTERS_ID,
		EquipmentDefinition.Slot.THRUSTERS
	)

func _save_equipment_choice(
	equipment_id: StringName,
	target_slot: EquipmentDefinition.Slot
) -> bool:
	if not storage_available:
		return false
	
	var save_key: String
	
	match target_slot:
		EquipmentDefinition.Slot.PRIMARY_WEAPON:
			save_key = "primary_weapon"
		
		EquipmentDefinition.Slot.ACTIVE_SYSTEM:
			save_key = "active_system"
		
		EquipmentDefinition.Slot.CHASSIS:
			save_key = "chassis"
		
		EquipmentDefinition.Slot.THRUSTERS:
			save_key = "thrusters"
		
		_:
			return false
	
	var had_previous_value := save_data.has_section_key(
		"loadout",
		save_key
	)
	
	var previous_value: Variant = save_data.get_value(
		"loadout",
		save_key,
		""
	)
	
	save_data.set_value(
		"loadout",
		save_key,
		String(equipment_id)
	)
	
	var error := save_data.save(SAVE_PATH)
	
	if error != OK:
		if had_previous_value:
			save_data.set_value(
				"loadout",
				save_key,
				previous_value
			)
		else:
			save_data.erase_section_key("loadout", save_key)
		
		push_error(
			"Could not save equipment choice: %s"
			% error_string(error)
		)
		return false
	return true
