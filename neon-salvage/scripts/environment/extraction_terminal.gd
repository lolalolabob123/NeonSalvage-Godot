extends Area2D

@export var mission_controller: FacilityMission

@onready var interaction_prompt: Label = $InteractionPrompt

func _process(_delta: float) -> void:
	interaction_prompt.visible = player_can_interact()
	
	if not is_instance_valid(mission_controller):
		return
	
	if mission_controller.transport_ready:
		interaction_prompt.text = "[E] EXTRACT"
	elif mission_controller.has_prototype:
		interaction_prompt.text = "[E] CALL EXTRACTION"
	else:
		interaction_prompt.text = "RECOVER PROTOTYPE FIRST"

func player_can_interact() -> bool:
	if not is_instance_valid(mission_controller):
		return false
	
	if mission_controller.extraction_complete:
		return false
	
	if (
		mission_controller.has_called_extraction
		and not mission_controller.transport_ready
	):
		return false
	
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			if int(body.get("current_health")) > 0:
				return true
	
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	
	if not player_can_interact():
		return
	
	var succeeded: bool = false
	
	if mission_controller.transport_ready:
		succeeded = mission_controller.complete_extraction()
	else:
		succeeded = mission_controller.request_extraction()
	
	if succeeded:
		interaction_prompt.hide()
		get_viewport().set_input_as_handled()
