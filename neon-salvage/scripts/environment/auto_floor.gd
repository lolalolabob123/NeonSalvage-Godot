@tool
extends Polygon2D

@export var west_wall: Node2D
@export var east_wall: Node2D
@export var north_wall: Node2D
@export var south_wall: Node2D

func _ready() -> void:
	_update_floor()
	set_process(Engine.is_editor_hint())

func _process(_delta: float) -> void:
	_update_floor()

func _update_floor() -> void:
	if (
		not is_instance_valid(west_wall)
		or not is_instance_valid(east_wall)
		or not is_instance_valid(north_wall)
		or not is_instance_valid(south_wall)
	):
		return
	
	var left := to_local(west_wall.global_position).x
	var right := to_local(east_wall.global_position).x
	var top := to_local(north_wall.global_position).y
	var bottom := to_local(south_wall.global_position).y
	
	var corners := PackedVector2Array([
		Vector2(left, top),
		Vector2(right, top),
		Vector2(right, bottom),
		Vector2(left, bottom)
	])
	
	if polygon != corners:
		polygon = corners
