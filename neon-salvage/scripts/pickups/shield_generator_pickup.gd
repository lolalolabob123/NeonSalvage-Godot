extends Area2D

@onready var interaction_prompt: Label = $InteractionPrompt


func _ready() -> void:
	interaction_prompt.hide()
	if ProgressStore.owns_shield_generator():
		queue_free()


func _process(_delta: float) -> void:
	interaction_prompt.visible = _has_player_in_range()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or not _has_player_in_range():
		return

	var mission := get_tree().get_first_node_in_group(
		"mission_controller"
	) as FacilityMission
	if mission != null and mission.recover_shield_generator():
		get_viewport().set_input_as_handled()
		queue_free()


func _has_player_in_range() -> bool:
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and int(body.get("current_health")) > 0:
			return true
	return false
