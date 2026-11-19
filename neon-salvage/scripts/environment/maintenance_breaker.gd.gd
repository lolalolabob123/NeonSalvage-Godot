extends Area2D

@export var mission_controller: FacilityMission

@onready var interaction_prompt: Label = $InteractionPrompt
@onready var status_strip: Polygon2D = $Panel/StatusStrip

func _process(delta: float) -> void:
	if not is_instance_valid(mission_controller):
		interaction_prompt.hide()
		return
	
	interaction_prompt.visible = _player_is_nearby()
	status_strip.color = Color("#F3AC57")
	
	if mission_controller.turbine_circuit_isolated:
		status_strip.color = Color("#B6FFD0")
		interaction_prompt.text = "CIRCUIT ISOLATED\nTURBINE DISCHARGES DISABLED"
	elif mission_controller.turbine_running:
		interaction_prompt.text = "TURBINE ALREADY RUNNING"
	else:
		interaction_prompt.text = "[E] ISOLATE TURBINE DISCHARGES"

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
	
	if mission_controller.isolate_turbine_circuit():
		get_viewport().set_input_as_handled()
