@tool
extends Node2D


func _draw() -> void:
	# Mounting plate.
	draw_rect(
		Rect2(-28, -10, 56, 20),
		Color("#203642")
	)

	# Metal housing.
	draw_rect(
		Rect2(-24, -8, 48, 16),
		Color("#6E8B98")
	)

	# Illuminated strip.
	draw_rect(
		Rect2(-19, -3, 38, 6),
		Color("#B6F5FF")
	)

	# Dark end caps.
	draw_rect(
		Rect2(-24, -8, 5, 16),
		Color("#304C5B")
	)

	draw_rect(
		Rect2(19, -8, 5, 16),
		Color("#304C5B")
	)
