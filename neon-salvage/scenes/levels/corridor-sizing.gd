@tool
extends Node2D

@export var west_end: Node2D
@export var east_end: Node2D
@export var north_wall: StaticBody2D
@export var south_wall: StaticBody2D

@export var passage_width: float = 160.0
@export var end_overlap: float = 16.0


func _ready() -> void:
	_update_walls()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	_update_walls()


func _update_walls() -> void:
	if (
		not is_instance_valid(west_end)
		or not is_instance_valid(east_end)
		or not is_instance_valid(north_wall)
		or not is_instance_valid(south_wall)
	):
		return

	var left := to_local(west_end.global_position).x
	var right := to_local(east_end.global_position).x

	if right <= left:
		return

	var center_x := (left + right) * 0.5
	var length := right - left + end_overlap * 2.0
	var wall_y := maxf(passage_width, 1.0) * 0.5 + 40.0

	_fit_wall(north_wall, Vector2(center_x, -wall_y), length)
	_fit_wall(south_wall, Vector2(center_x, wall_y), length)


func _fit_wall(
	wall: StaticBody2D,
	at_position: Vector2,
	length: float
) -> void:
	if not wall.position.is_equal_approx(at_position):
		wall.position = at_position

	var requested_size := Vector2(length, 80.0)
	var current_size: Vector2 = wall.get("wall_size")

	if not current_size.is_equal_approx(requested_size):
		wall.set("wall_size", requested_size)
