extends Node2D

@export var interaction_distance: float = 96.0
@export var auto_close_delay: float = 0.6

@onready var collision_shape: CollisionShape2D = $DoorBody/CollisionShape2D
@onready var panel: Polygon2D = $Panel
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var sentry_approach_area: Area2D = $SentryApproachArea

var is_open: bool = false
var close_timer: float = 0.0

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

func _ready() -> void:
	sentry_approach_area.body_entered.connect(
		_on_sentry_approach
	)

func _on_sentry_approach(body: Node2D) -> void:
	if is_open:
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
