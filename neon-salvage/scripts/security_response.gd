extends Node2D

@export var mission_controller: FacilityMission
@export var sentry_scene: PackedScene
@export var extraction_terminal: Node2D

@onready var reinforcement_spawn: Marker2D = $ReinforcementSpawn

var response_deployed: bool = false

func _ready() -> void:
	if (
		not is_instance_valid(mission_controller)
		or sentry_scene == null
		or not is_instance_valid(extraction_terminal)
	):
		push_error("Assign all three SecurityResponse Inspector fields.")
		return
	
	mission_controller.extraction_called.connect(
		_deploy_reinforcement
	)
	
func _deploy_reinforcement() -> void:
	if response_deployed:
		return
		
	var sentry := sentry_scene.instantiate() as CharacterBody2D
		
	if sentry == null:
		push_error("SecurityResponse needs the SentryDrone scene.")
		return
		
	# Set position before _ready records the Sentry's home.
	sentry.position = to_local(reinforcement_spawn.global_position)
	sentry.set("patrol_route", null)
	add_child(sentry)
	
	sentry.call(
		"respond_to_alarm",
		extraction_terminal.global_position
	)
		
	response_deployed = true
