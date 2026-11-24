@tool
extends StaticBody2D

@export var wall_size: Vector2 = Vector2(400, 80):
	set(value):
		wall_size = Vector2(
			maxf(value.x, 40.0),
			maxf(value.y, 40.0)
		)
		queue_redraw()
		call_deferred("_update_collision")


func _ready() -> void:
	_update_collision()
	queue_redraw()


func _update_collision() -> void:
	var collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	if collision == null:
		return

	# Each instance receives its own shape.
	var rectangle := RectangleShape2D.new()
	rectangle.size = wall_size

	collision.set_deferred("shape", rectangle)


func _draw() -> void:
	var bounds := Rect2(-wall_size * 0.5, wall_size)
	var face_depth := 16.0

	# Dark lower face.
	draw_rect(bounds, Color("#203642"))

	# Upper surface.
	var top := Rect2(
		bounds.position,
		Vector2(wall_size.x, wall_size.y - face_depth)
	)

	draw_rect(top, Color("#52717F"))

	# Inset surface leaves a metal frame around the top.
	draw_rect(
		top.grow(-6.0),
		Color("#354F5D")
	)

	# Light catches the upper edge.
	draw_line(
		bounds.position + Vector2(3, 2),
		bounds.position + Vector2(wall_size.x - 3, 2),
		Color("#6E8B98"),
		2.0
	)

	# Dark seam between the upper surface and front face.
	var seam_y := bounds.position.y + top.size.y

	draw_line(
		Vector2(bounds.position.x, seam_y),
		Vector2(bounds.end.x, seam_y),
		Color("#132630"),
		2.0
	)
