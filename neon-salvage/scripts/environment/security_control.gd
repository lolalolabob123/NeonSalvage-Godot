extends Area2D
@export var mission_controller: FacilityMission

@onready var interaction_prompt: Label = $InteractionPrompt
@onready var status_strip: Polygon2D = $Panel/StatusStrip

func _process(_delta: float) -> void:
	if not is_instance_valid(mission_controller):
		interaction_prompt.hide()
		return
	
	interaction_prompt.visible = _player_is_nearby()
	status_strip.color = Color("#F3AC57")
	
	if mission_controller.extraction_response_suppressed:
		status_strip.color = Color("#B6FFD0")
		interaction_prompt.text = "EXTRACTION REINFORCEMENT DISABLED"
	elif mission_controller.has_called_extraction:
		interaction_prompt.text = "RESPONSE ALREADY DISPATCHED"
	elif not mission_controller.has_restored_power:
		interaction_prompt.text = "POWER REQUIRED - RESTART TURBINE"
	else:
		interaction_prompt.text = "[E] DISABLE EXTRACTION REINFORCEMENT"

func _player_is_nearby() -> bool:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			if int(body.get("current_health")) > 0:
				return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	if not is_instance_valid(mission_controller):
		return
	if not _player_is_nearby():
		return
	
	if mission_controller.suppress_extraction_response():
		get_viewport().set_input_as_handled()
