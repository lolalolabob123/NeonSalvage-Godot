class_name FacilityMission
extends Node

signal prototype_recovered
signal extraction_called
signal transport_arrived
signal mission_completed
signal security_card_collected

@export var extraction_duration: float = 8.0

var has_prototype: bool = false
var has_security_card: bool = false
var has_called_extraction: bool = false
var extraction_time_left: float = 0.0
var transport_ready: bool = false
var extraction_complete: bool = false
var extracted_salvage: int = 0

func _ready() -> void:
	add_to_group("mission_controller")

func recover_prototype() -> bool:
	if has_prototype:
		return false
	
	has_prototype = true
	prototype_recovered.emit()
	return true

func request_extraction() -> bool:
	if not has_prototype or has_called_extraction:
		return false
	
	has_called_extraction = true
	extraction_time_left = extraction_duration
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
	if not has_prototype or not transport_ready or extraction_complete:
		return false
	
	var player := get_tree().get_first_node_in_group("player")
	
	if not is_instance_valid(player):
		return false
	
	if int(player.get("current_health")) <= 0:
		return false
	
	var mission_salvage: int = int(player.get("salvage_total"))
	
	if not ProgressStore.bank_salvage(mission_salvage):
		push_error("Extraction could not finish because progress was not saved.")
		return false
	
	extracted_salvage = mission_salvage
	
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
