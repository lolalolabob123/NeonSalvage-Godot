class_name FacilityMission
extends Node

signal prototype_recovered
signal extraction_called
signal transport_arrived
signal mission_completed
signal security_card_collected
signal power_restored
signal mission_stage_changed
signal turbine_started
signal turbine_startup_begun

enum ObjectiveType {
	RECOVER_PROTOTYPE,
	RESTORE_POWER
}

@export var extraction_duration: float = 8.0
@export var objective_type = ObjectiveType.RECOVER_PROTOTYPE
@export var allow_early_extraction: bool = false

var has_prototype: bool = false
var has_unsecured_shield: bool = false
var has_security_card: bool = false
var has_called_extraction: bool = false
var extraction_time_left: float = 0.0
var transport_ready: bool = false
var extraction_complete: bool = false
var extracted_salvage: int = 0
var secured_shield_this_run: bool = false
var has_restored_power: bool = false
var power_fault_diagnosed: bool = false
var turbine_running: bool = false
var turbine_startup_active: bool = false
var extraction_response_suppressed: bool = false
var turbine_circuit_isolated: bool = false
var objective_completed_on_extraction: bool = false
var unsecured_gear: Array[StringName] = []
var secured_gear_this_run: Array[StringName] = []

func _ready() -> void:
	add_to_group("mission_controller")

func recover_gear(gear_id: StringName) -> bool:
	if extraction_complete:
		return false

	if not ProgressStore.GEAR.has(gear_id):
		return false

	if ProgressStore.owns_gear(gear_id):
		return false

	if unsecured_gear.has(gear_id):
		return false

	unsecured_gear.append(gear_id)

	# Preserve compatibility with the existing shield code.
	if gear_id == ProgressStore.SHIELD_GENERATOR_ID:
		has_unsecured_shield = true

	mission_stage_changed.emit()
	return true

func recover_shield_generator() -> bool:
	return recover_gear(ProgressStore.SHIELD_GENERATOR_ID)

func recover_prototype() -> bool:
	if has_prototype:
		return false
	
	has_prototype = true
	prototype_recovered.emit()
	return true

func request_extraction() -> bool:
	if not can_call_extraction():
		return false
	
	has_called_extraction = true
	extraction_time_left = extraction_duration
	
	if ProgressStore.has_skill(ProgressStore.EMERGENCY_PATCH_ID):
		var player := get_tree().get_first_node_in_group("player")
		player.call("apply_emergency_patch")
	
	extraction_called.emit()
	return true

func _physics_process(delta: float) -> void:
	if not has_called_extraction or transport_ready:
		return
	
	var player := get_tree().get_first_node_in_group("player")
	
	if not is_instance_valid(player):
		return
	
	if int(player.get("current_health")) <= 0:
		return
	
	extraction_time_left = maxf(extraction_time_left - delta, 0.0)
	
	if extraction_time_left <= 0.0:
		transport_ready = true
		transport_arrived.emit()

func complete_extraction() -> bool:
	if (
		not has_called_extraction
		or not transport_ready
		or extraction_complete
	):
		return false

	var player := get_tree().get_first_node_in_group("player")

	if not is_instance_valid(player):
		return false

	if int(player.get("current_health")) <= 0:
		return false

	var mission_salvage: int = int(player.get("salvage_total"))

	if not ProgressStore.bank_extraction(
		mission_salvage,
		unsecured_gear
	):
		push_error("Extraction could not finish because progress was not saved.")
		return false

	extracted_salvage = mission_salvage
	secured_gear_this_run.assign(unsecured_gear)
	secured_shield_this_run = has_unsecured_shield
	objective_completed_on_extraction = is_objective_complete()

	player.set("salvage_total", 0)
	player.emit_signal("salvage_changed", 0)

	extraction_complete = true
	mission_completed.emit()
	get_tree().paused = true
	return true

func collect_security_card() -> void:
	if has_security_card:
		return
	
	has_security_card = true
	security_card_collected.emit()

func is_objective_complete() -> bool:
	match objective_type:
		ObjectiveType.RECOVER_PROTOTYPE:
			return has_prototype
		ObjectiveType.RESTORE_POWER:
			return has_restored_power
		_:
			return false

func restore_power() -> bool:
	if objective_type != ObjectiveType.RESTORE_POWER:
		return false
	
	if not turbine_running:
		return false
	
	if has_restored_power or extraction_complete:
		return false
	
	has_restored_power = true
	power_restored.emit()
	return true

func get_objective_complete_text() -> String:
	match objective_type:
		ObjectiveType.RESTORE_POWER:
			return "POWER RESTORED"
		_:
			return "PROTOTYPE RECOVERED"

func get_extraction_requirement_text() -> String:
	match objective_type:
		ObjectiveType.RESTORE_POWER:
			return "RESTORE STATION POWER FIRST"
		_:
			return "RECOVER PROTOTYPE FIRST"

func get_objective_instruction() -> String:
	if objective_type == ObjectiveType.RESTORE_POWER:
		if turbine_startup_active:
			return "Maintain turbine restart: stay inside the control ring."

		if power_fault_diagnosed:
			return "Restart the turbine in Turbine Hall."

		return "Restart the turbine. Control Room contains fault information."

	return "Recover the prototype in the security room."

func diagnose_power_fault() -> bool:
	if objective_type != ObjectiveType.RESTORE_POWER:
		return false
	
	if power_fault_diagnosed or extraction_complete or turbine_running:
		return false
	
	power_fault_diagnosed = true
	mission_stage_changed.emit()
	return true

func start_turbine() -> bool:
	if objective_type != ObjectiveType.RESTORE_POWER:
		return false

	if not turbine_startup_active:
		return false

	if turbine_running or extraction_complete:
		return false

	turbine_startup_active = false
	turbine_running = true

	restore_power()

	turbine_started.emit()
	mission_stage_changed.emit()
	return true

func begin_turbine_restart() -> bool:
	if objective_type != ObjectiveType.RESTORE_POWER:
		return false

	if turbine_startup_active or turbine_running or extraction_complete:
		return false

	turbine_startup_active = true
	turbine_startup_begun.emit()
	mission_stage_changed.emit()
	return true

func suppress_extraction_response() -> bool:
	if objective_type != ObjectiveType.RESTORE_POWER:
		return false
	
	if not has_restored_power:
		return false
	
	if extraction_response_suppressed or has_called_extraction or extraction_complete:
		return false
	
	extraction_response_suppressed = true
	
	mission_stage_changed.emit()
	return true

func isolate_turbine_circuit() -> bool:
	if objective_type != ObjectiveType.RESTORE_POWER:
		return false
	
	if turbine_circuit_isolated or turbine_running or extraction_complete:
		return false
	
	turbine_circuit_isolated = true
	mission_stage_changed.emit()
	return true

func can_call_extraction() -> bool:
	if has_called_extraction or extraction_complete:
		return false
	
	return is_objective_complete() or allow_early_extraction
