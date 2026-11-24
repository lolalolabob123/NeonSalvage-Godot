@tool
extends Node2D

@export var room_size: Vector2 = Vector2(1200, 800):
	set(value):
		room_size = Vector2(
			maxf(value.x, 100.0),
			maxf(value.y, 100.0)
		)
		queue_redraw()

@export_range(50.0, 200.0, 10.0) var panel_size: float = 100.0:
	set(value):
		panel_size = maxf(value, 50.0)
		queue_redraw()


func _draw() -> void:
	var origin := -room_size * 0.5
	var columns := ceili(room_size.x / panel_size)
	var rows := ceili(room_size.y / panel_size)

	# Dark material visible between the panels.
	draw_rect(
		Rect2(origin, room_size),
		Color("#172B35")
	)

	for row in range(rows):
		for column in range(columns):
			var offset := Vector2(column, row) * panel_size

			var tile_size := Vector2(
				minf(panel_size, room_size.x - offset.x),
				minf(panel_size, room_size.y - offset.y)
			)

			var panel := Rect2(
				origin + offset + Vector2(1, 1),
				tile_size - Vector2(2, 2)
			)

			var panel_color := Color("#19303C")

			if (column + row) % 2 == 0:
				panel_color = Color("#1B323E")

			draw_rect(panel, panel_color)

			# Subtle highlight along the upper edge.
			draw_line(
				panel.position + Vector2(3, 2),
				panel.position + Vector2(panel.size.x - 3, 2),
				Color(0.38, 0.54, 0.60, 0.12),
				1.0
			)

	# A restrained perimeter frame.
	draw_rect(
		Rect2(origin, room_size).grow(-4.0),
		Color("#304B58"),
		false,
		4.0
	)
