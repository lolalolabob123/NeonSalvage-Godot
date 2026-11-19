extends Node2D

@export var mission_controller: FacilityMission
@export var prompt_distance: float = 180.0

@onready var collision_shape: CollisionShape2D = $DoorBody/CollisionShape2D
@onready var panel: Polygon2D = $Panel
@onready var interaction_prompt: Label = $InteractionPrompt

var is_open: bool = false


func _ready() -> void:
	interaction_prompt.hide()
	panel.show()
	collision_shape.set_deferred("disabled", false)

	if not is_instance_valid(mission_controller):
		push_error("ResearchAccessDoor needs a MissionController.")
		return

	mission_controller.power_restored.connect(_open_gate)

	if mission_controller.has_restored_power:
		_open_gate()


func _open_gate() -> void:
	is_open = true
	collision_shape.set_deferred("disabled", true)
	panel.hide()


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	interaction_prompt.hide()

	if not is_instance_valid(player):
		return

	if int(player.get("current_health")) <= 0:
		return

	if global_position.distance_to(player.global_position) > prompt_distance:
		return

	interaction_prompt.show()

	if is_open:
		interaction_prompt.text = "RESEARCH ACCESS ONLINE"
		interaction_prompt.modulate = Color("#B6FFD0")
	else:
		interaction_prompt.text = (
			"RESEARCH ACCESS OFFLINE\n"
			+ "Restore turbine power to enter."
		)
		interaction_prompt.modulate = Color("#F3AC57")
