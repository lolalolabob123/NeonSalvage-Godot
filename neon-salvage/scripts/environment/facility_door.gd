extends Node2D

@export var interaction_distance: float = 96.0
@export var auto_close_delay: float = 0.6
@export var requires_security_card: bool = false

@onready var collision_shape: CollisionShape2D = $DoorBody/CollisionShape2D
@onready var panel: Polygon2D = $Panel
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var sentry_approach_area: Area2D = $SentryApproachArea

var is_open: bool = false
var close_timer: float = 0.0
var access_granted: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if is_open or not event.is_action_pressed("interact"):
		return
	
	var player := get_tree().get_first_node_in_group("player") as Node2D
	
	if not is_instance_valid(player):
		return
	
	if int(player.get("current_health")) <= 0:
		return
	
	if global_position.distance_to(player.global_position) > interaction_distance:
		return
	
	if is_locked():
		if not player_has_security_card():
			get_viewport().set_input_as_handled()
			return
		
		access_granted = true
	
	open_door()
	get_viewport().set_input_as_handled()

func open_door() -> void:
	is_open = true
	close_timer = auto_close_delay
	collision_shape.set_deferred("disabled", true)
	panel.hide()
	interaction_prompt.hide()

func _process(_delta: float) -> void:
	interaction_prompt.hide()
	
	if is_open:
		return
	
	var player := get_tree().get_first_node_in_group("player") as Node2D
	
	if not is_instance_valid(player):
		return
	
	interaction_prompt.visible = (
		global_position.distance_to(player.global_position)
		<= interaction_distance
	)
	
	if is_locked():
		if player_has_security_card():
			interaction_prompt.text = "[E] UNLOCK DOOR"
		else:
			interaction_prompt.text = "SECURITY CARD REQUIRED"
	else:
		interaction_prompt.text = "[E] OPEN DOOR"

func _ready() -> void:
	sentry_approach_area.body_entered.connect(
		_on_sentry_approach
	)

func _on_sentry_approach(body: Node2D) -> void:
	if is_open or is_locked():
		return
	
	if not body.is_in_group("sentries"):
		return
	
	if int(body.get("current_health")) <= 0:
		return
	
	open_door()

func _physics_process(delta: float) -> void:
	if not is_open:
		return
	
	# Keep the door open while a drone occupies the doorway.
	for body in sentry_approach_area.get_overlapping_bodies():
		if body.is_in_group("player") or body.is_in_group("sentries"):
			close_timer = auto_close_delay
			return
	
	# Close only after the doorway has remained clear.
	close_timer = maxf(close_timer - delta, 0.0)
	
	if close_timer <= 0.0:
		close_door()
	
func close_door() -> void:
	is_open = false
	collision_shape.set_deferred("disabled", false)
	panel.show()

func is_locked() -> bool:
	return requires_security_card and not access_granted

func player_has_security_card() -> bool:
	var mission := get_tree().get_first_node_in_group(
		"mission_controller"
	) as FacilityMission
	
	return is_instance_valid(mission) and mission.has_security_card
