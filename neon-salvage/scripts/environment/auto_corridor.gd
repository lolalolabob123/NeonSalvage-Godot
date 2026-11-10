@tool
extends Node2D

@export var west_end: Node2D
@export var east_end: Node2D
@export var north_wall: StaticBody2D
@export var south_wall: StaticBody2D

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
	var wall_length := right - left + 32.0
	_fit_wall(north_wall, center_x, wall_length)
	_fit_wall(south_wall, center_x, wall_length)

func _fit_wall(wall: StaticBody2D, center_x: float, wall_length: float) -> void:
	var collider := wall.get_node("CollisionShape2D") as CollisionShape2D
	var rectangle := collider.shape as RectangleShape2D
	if rectangle == null:
		return

	wall.position.x = center_x
	if is_equal_approx(rectangle.size.x, wall_length):
		return

	var half_change := (wall_length - rectangle.size.x) * 0.5
	var art := wall.get_node("Polygon2D") as Polygon2D
	var trim := wall.get_node_or_null("InnerTrim") as Line2D

	art.polygon = resize_points(art.polygon, half_change)
	if trim != null:
		trim.points = resize_points(trim.points, half_change)

	var resized_shape := rectangle.duplicate() as RectangleShape2D
	resized_shape.size = Vector2(wall_length, rectangle.size.y)
	collider.shape = resized_shape

func resize_points(points: PackedVector2Array, half_change: float) -> PackedVector2Array:
	for i in range(points.size()):
		points[i].x += signf(points[i].x) * half_change
	return points
