extends Area2D

@export var gear_id: StringName

@export_range(0, 100, 1) var repeat_salvage_amount: int = 0

@onready var interaction_prompt: Label = $InteractionPrompt

var is_repeat_reward: bool = false

func _ready() -> void:
	interaction_prompt.hide()

	var equipment := ProgressStore.get_equipment(gear_id)

	if equipment == null:
		push_error("Equipment pickup needs a valid Gear ID.")
		set_process(false)
		set_process_unhandled_input(false)
		return

	if ProgressStore.owns_equipment(gear_id):
		if repeat_salvage_amount <= 0:
			queue_free()
			return

		is_repeat_reward = true

		interaction_prompt.text = (
			"[E] RECOVER SALVAGE CACHE\n"
			+ "%d salvage — extract to bank."
		) % repeat_salvage_amount

		var visual := get_node_or_null("Polygon2D") as Polygon2D

		if visual != null:
			visual.color = Color("#31CBE0")

	else:
		interaction_prompt.text = (
			"[E] RECOVER %s\nExtract to secure."
		) % equipment.display_name.to_upper()

func _process(_delta: float) -> void:
	interaction_prompt.visible = _has_player_in_range()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or event.is_echo():
		return

	if not _has_player_in_range():
		return

	if is_repeat_reward:
		for body in get_overlapping_bodies():
			if (
				body.is_in_group("player")
				and int(body.get("current_health")) > 0
			):
				body.call("add_salvage", repeat_salvage_amount)
				get_viewport().set_input_as_handled()
				queue_free()
				return

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
