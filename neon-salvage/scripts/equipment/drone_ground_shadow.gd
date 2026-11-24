@tool
extends Node2D

@export var shadow_size: Vector2 = Vector2(64, 32)
@export var ground_offset: Vector2 = Vector2(6, 12)
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.28)

var follow_target: Node2D

func _ready() -> void:
	follow_target = get_parent() as Node2D
	
	# Keep the shadow flat on the ground as the drone turns.
	top_level = true
	z_index = -1
	
	_update_position()
	queue_redraw()

func _process(_delta: float) -> void:
	_update_position()
	queue_redraw()

func _update_position() -> void:
	if not is_instance_valid(follow_target):
		return
	
	global_position = follow_target.global_position + ground_offset

func _draw() -> void:
	# Stretch a circle into a ground ellipse.
	draw_set_transform(
		Vector2.ZERO,
		0.0,
		shadow_size * 0.5
	)
	
	draw_circle(
		Vector2.ZERO,
		1.0,
		shadow_color
	)
	
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
