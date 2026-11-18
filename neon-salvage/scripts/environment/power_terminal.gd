extends Area2D

enum TerminalRole {
	POWER_CONTROL,
	TURBINE_STARTER,
}

@export var mission_controller: FacilityMission
@export var terminal_role: TerminalRole = TerminalRole.POWER_CONTROL

@onready var interaction_prompt: Label = $InteractionPrompt
@onready var status_strip: Polygon2D = $Panel/StatusStrip


func _process(_delta: float) -> void:
	if not is_instance_valid(mission_controller):
		interaction_prompt.hide()
		return

	interaction_prompt.visible = _player_is_nearby()
	status_strip.color = Color("#F3AC57")

	if terminal_role == TerminalRole.TURBINE_STARTER:
		if mission_controller.turbine_running:
			status_strip.color = Color("#B6FFD0")
			interaction_prompt.text = "TURBINE RUNNING"
		else:
			interaction_prompt.text = "[E] START TURBINE"
		return

	if mission_controller.has_restored_power:
		status_strip.color = Color("#B6FFD0")
		interaction_prompt.text = "POWER RESTORED"
	elif mission_controller.turbine_running:
		interaction_prompt.text = "[E] RESTORE POWER"
	elif mission_controller.power_fault_diagnosed:
		interaction_prompt.text = "TURBINE OFFLINE — RESTART IN TURBINE HALL"
	else:
		interaction_prompt.text = "[E] DIAGNOSE POWER FAULT"


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

	var succeeded: bool = false

	if terminal_role == TerminalRole.TURBINE_STARTER:
		succeeded = mission_controller.start_turbine()
	elif mission_controller.turbine_running:
		succeeded = mission_controller.restore_power()
	else:
		succeeded = mission_controller.diagnose_power_fault()

	if succeeded:
		get_viewport().set_input_as_handled()
