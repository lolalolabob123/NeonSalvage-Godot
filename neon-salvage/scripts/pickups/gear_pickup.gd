extends Area2D

@export var gear_id: StringName

@onready var interaction_prompt: Label = $InteractionPrompt


func _ready() -> void:
	interaction_prompt.hide()

	var gear: Dictionary = ProgressStore.GEAR.get(gear_id, {})

	if gear.is_empty():
		push_error("Gear pickup needs a valid Gear ID.")
		set_process(false)
		set_process_unhandled_input(false)
		return

	interaction_prompt.text = "[E] RECOVER %s\nExtract to secure." % (
		str(gear["display_name"]).to_upper()
	)

	if ProgressStore.owns_gear(gear_id):
		queue_free()


func _process(_delta: float) -> void:
	interaction_prompt.visible = _has_player_in_range()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or event.is_echo():
		return

	if not _has_player_in_range():
		return

	var mission := get_tree().get_first_node_in_group(
		"mission_controller"
	) as FacilityMission

	if mission == null:
		return

	if mission.recover_gear(gear_id):
		get_viewport().set_input_as_handled()
		queue_free()


func _has_player_in_range() -> bool:
	for body in get_overlapping_bodies():
		if (
			body.is_in_group("player")
			and int(body.get("current_health")) > 0
		):
			return true

	return false
