extends Node2D

@export var mission_controller: FacilityMission
@export var sentry_scene: PackedScene
@export var turbine_starter: Node2D
@export var response_delay: float = 2.0

@onready var response_spawn: Marker2D = $ResponseSpawn
@onready var warning_label: Label = $WarningLabel

var response_triggered: bool = false


func _ready() -> void:
	warning_label.hide()

	if (
		not is_instance_valid(mission_controller)
		or sentry_scene == null
		or not is_instance_valid(turbine_starter)
	):
		push_error("Assign all TurbineResponse references.")
		return

	mission_controller.turbine_startup_begun.connect(
		_on_startup_begun
	)


func _on_startup_begun() -> void:
	if response_triggered:
		return

	response_triggered = true
	warning_label.text = "SENTRY INBOUND FROM WEST"
	warning_label.show()

	get_tree().create_timer(maxf(response_delay, 0.1)).timeout.connect(
		_deploy_sentry
	)


func _deploy_sentry() -> void:
	warning_label.hide()

	if not is_instance_valid(mission_controller):
		return

	if mission_controller.extraction_complete:
		return

	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return

	if int(player.get("current_health")) <= 0:
		return

	var sentry := sentry_scene.instantiate() as CharacterBody2D
	if sentry == null:
		push_error("Assign SentryDrone.tscn to TurbineResponse.")
		return

	sentry.position = to_local(response_spawn.global_position)
	sentry.set("patrol_route", null)
	add_child(sentry)

	sentry.call(
		"respond_to_alarm",
		turbine_starter.global_position
	)
