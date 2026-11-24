@tool
extends Node2D

@export var rotation_speed_degrees: float = 45.0

var fan_angle: float = 0.0


func _process(delta: float) -> void:
	# Keep the editor preview still.
	if Engine.is_editor_hint():
		return

	fan_angle = fposmod(
		fan_angle + deg_to_rad(rotation_speed_degrees) * delta,
		TAU
	)

	queue_redraw()


func _draw() -> void:
	# Outer casing.
	draw_rect(
		Rect2(-36, -36, 72, 72),
		Color("#203642")
	)

	draw_rect(
		Rect2(-33, -33, 66, 66),
		Color("#52717F")
	)

	# Recess behind the fan.
	draw_circle(
		Vector2.ZERO,
		28.0,
		Color("#101F29")
	)

	# Four rotating blades.
	var blade_shape := PackedVector2Array([
		Vector2(-3, -5),
		Vector2(3, -5),
		Vector2(12, -22),
		Vector2(-7, -24),
	])

	for blade_index in range(4):
		var angle := fan_angle + float(blade_index) * PI * 0.5
		var rotated_blade := PackedVector2Array()

		for point in blade_shape:
			rotated_blade.append(point.rotated(angle))

		draw_colored_polygon(
			rotated_blade,
			Color("#45616E")
		)

	# Stationary central hub.
	draw_circle(
		Vector2.ZERO,
		6.0,
		Color("#78939F")
	)

	# Protective grille stays still while the blades turn.
	for grille_index in range(-2, 3):
		var line_y := float(grille_index) * 9.0

		draw_line(
			Vector2(-24, line_y),
			Vector2(24, line_y),
			Color("#263E4A"),
			2.0
		)

	# Mounting screws.
	for screw_position in [
		Vector2(-28, -28),
		Vector2(28, -28),
		Vector2(-28, 28),
		Vector2(28, 28),
	]:
		draw_circle(
			screw_position,
			2.0,
			Color("#A0B2BA")
		)
