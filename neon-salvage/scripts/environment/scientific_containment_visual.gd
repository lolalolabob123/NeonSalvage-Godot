@tool
extends Node2D

var animation_time: float = 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	animation_time += delta
	queue_redraw()


func _draw() -> void:
	# Main housing and dark lower face.
	draw_rect(
		Rect2(-60, -72, 120, 144),
		Color("#203642")
	)

	# Upper cap.
	draw_rect(
		Rect2(-60, -72, 120, 24),
		Color("#52717F")
	)

	draw_rect(
		Rect2(-48, -66, 96, 10),
		Color("#354F5D")
	)

	# Recess behind the glass.
	draw_rect(
		Rect2(-48, -48, 96, 104),
		Color("#102631")
	)

	# Contained sample: a restrained cyan crystal.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0, -28),
			Vector2(17, -8),
			Vector2(12, 20),
			Vector2(0, 30),
			Vector2(-12, 20),
			Vector2(-17, -8),
		]),
		Color("#3C8796")
	)

	draw_line(
		Vector2(0, -24),
		Vector2(0, 25),
		Color("#7BB8C3"),
		2.0
	)

	# Transparent glass tint.
	draw_rect(
		Rect2(-48, -48, 96, 104),
		Color(0.25, 0.65, 0.73, 0.12)
	)

	# Glass reflection.
	draw_line(
		Vector2(-34, -38),
		Vector2(-34, 42),
		Color(0.7, 0.9, 1.0, 0.18),
		3.0
	)

	# Structural side rails.
	draw_rect(
		Rect2(-58, -48, 10, 104),
		Color("#52717F")
	)

	draw_rect(
		Rect2(48, -48, 10, 104),
		Color("#52717F")
	)

	# Lower control housing.
	draw_rect(
		Rect2(-60, 56, 120, 16),
		Color("#304C5B")
	)

	# Slow status-light pulse.
	var brightness := 0.65 + 0.15 * sin(animation_time * 1.5)

	draw_rect(
		Rect2(-20, 61, 40, 4),
		Color("#31CBE0") * Color(
			brightness,
			brightness,
			brightness,
			1.0
		)
	)
