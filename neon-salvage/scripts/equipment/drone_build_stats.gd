class_name DroneBuildStats
extends RefCounted

const BASE_HULL: int = 5
const BASE_MOVE_SPEED: float = 240.0
const BASE_DASH_SPEED: float = 950.0
const BASE_DASH_DURATION: float = 0.18
const BASE_DASH_COOLDOWN: float = 2

const SHIELD_DURATION: float = 1.5
const SHIELD_COOLDOWN: float = 8.0

const EMP_RADIUS: float = 220.0
const EMP_STUN_DURATION: float = 2.0
const EMP_COOLDOWN: float = 10.0

static func calculate(
	base_hull: int = BASE_HULL,
	base_move_speed: float = BASE_MOVE_SPEED,
	base_dash_speed: float = BASE_DASH_SPEED,
	base_dash_duration: float = BASE_DASH_DURATION,
	base_dash_cooldown: float = BASE_DASH_COOLDOWN
) -> Dictionary:
	var hull := base_hull
	var movement := base_move_speed
	var dash_speed := base_dash_speed
	var dash_cooldown := base_dash_cooldown
	
	if ProgressStore.has_skill(ProgressStore.HULL_REINFORCEMENT_ID):
		hull += 1
	
	if ProgressStore.has_skill(ProgressStore.HULL_REINFORCEMENT_II_ID):
		hull += 1
	
	var chassis := ProgressStore.get_equipped_chassis()
	
	if chassis != null:
		hull += chassis.hull_bonus
		movement *= chassis.move_speed_multiplier
	
	var thrusters := ProgressStore.get_equipped_thrusters()
	
	if thrusters != null:
		dash_speed *= thrusters.dash_speed_multiplier
		dash_cooldown *= thrusters.dash_cooldown_multiplier
	
	return {
		"maximum_hull": maxi(hull, 1),
		"movement_speed": movement,
		"dash_speed": dash_speed,
		"dash_distance": dash_speed * base_dash_duration,
		"dash_cooldown": dash_cooldown,
	}

static func get_system_summary() -> String:
	match ProgressStore.selected_system:
		ProgressStore.SHIELD_GENERATOR_ID:
			return "Shield: %.1fs protection / %.1fs cooldown after expiry" % [
				SHIELD_DURATION,
				SHIELD_COOLDOWN,
			]

		ProgressStore.EMP_EMITTER_ID:
			return "EMP: %.0fpx radius / %.1fs stun / %.1fs cooldown" % [
				EMP_RADIUS,
				EMP_STUN_DURATION,
				EMP_COOLDOWN,
			]

	return "Active system: None"
