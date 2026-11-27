extends "res://scripts/environment/facility_door.gd"

@export var slide_duration: float = 0.24

@onready var upper_leaf: Sprite2D = $Panel/UpperLeaf
@onready var lower_leaf: Sprite2D = $Panel/LowerLeaf
@onready var status_lights: Sprite2D = $Frame/StatusLights

var slide_tween: Tween
var moving: bool = false
var closing: bool = false


func _ready() -> void:
	super._ready()

	panel.show()
	upper_leaf.position = Vector2.ZERO
	lower_leaf.position = Vector2.ZERO

	# The leaves slide behind the stationary housings.
	$Frame.z_index = 1


func _process(delta: float) -> void:
	super._process(delta)

	var access_unavailable := (
		is_locked() and not player_has_security_card()
	)

	status_lights.self_modulate = (
		Color("#F3AC57")
		if access_unavailable
		else Color("#28C4D8")
	)


func _physics_process(delta: float) -> void:
	if closing and _doorway_occupied():
		open_door()
		return

	if moving:
		return

	super._physics_process(delta)


func open_door() -> void:
	if is_open and not closing:
		return

	is_open = true
	moving = true
	closing = false
	close_timer = auto_close_delay

	panel.show()
	interaction_prompt.hide()
	_slide_leaves(true)


func close_door() -> void:
	if moving or not is_open:
		return

	if _doorway_occupied():
		close_timer = auto_close_delay
		return

	moving = true
	closing = true
	_slide_leaves(false)


func _slide_leaves(opening: bool) -> void:
	if slide_tween != null:
		slide_tween.kill()

	var upper_y := -80.0 if opening else 0.0
	var lower_y := 80.0 if opening else 0.0
	var duration := maxf(slide_duration, 0.05)

	slide_tween = create_tween()
	slide_tween.set_parallel(true)
	slide_tween.set_trans(Tween.TRANS_QUAD)
	slide_tween.set_ease(Tween.EASE_IN_OUT)

	slide_tween.tween_property(
		upper_leaf, "position:y", upper_y, duration
	)
	slide_tween.tween_property(
		lower_leaf, "position:y", lower_y, duration
	)

	if opening:
		slide_tween.finished.connect(_finish_opening)
	else:
		slide_tween.finished.connect(_finish_closing)


func _finish_opening() -> void:
	collision_shape.set_deferred("disabled", true)
	moving = false
	closing = false
	close_timer = auto_close_delay


func _finish_closing() -> void:
	# Recheck before restoring the blocking collision.
	if _doorway_occupied():
		open_door()
		return

	is_open = false
	moving = false
	closing = false
	collision_shape.set_deferred("disabled", false)


func _doorway_occupied() -> bool:
	for body in sentry_approach_area.get_overlapping_bodies():
		if (
			body.is_in_group("player")
			or body.is_in_group("sentries")
		):
			return true

	return false
