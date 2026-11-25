@tool
extends Sprite2D

enum BodyType {
	SENTRY,
	INTERCEPTOR,
}

@export var body_type: BodyType = BodyType.SENTRY:
	set(value):
		body_type = value
		queue_redraw()


func _draw() -> void:
	match body_type:
		BodyType.SENTRY:
			_draw_sentry()

		BodyType.INTERCEPTOR:
			_draw_interceptor()

func _draw_sentry() -> void:
	# Lower chassis creates depth beneath the armour.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-20, -22),
			Vector2(20, -22),
			Vector2(28, -10),
			Vector2(28, 20),
			Vector2(16, 29),
			Vector2(-16, 29),
			Vector2(-28, 20),
			Vector2(-28, -10),
		]),
		Color("#14232D")
	)

	# Broad shoulder armour.
	_armour_panel(
		Rect2(-30, -16, 15, 34),
		Color("#84959A")
	)

	_armour_panel(
		Rect2(15, -16, 15, 34),
		Color("#84959A")
	)

	# Central raised housing.
	_armour_panel(
		Rect2(-16, -22, 32, 45),
		Color("#607B87")
	)

	# Rear engine housings.
	_armour_panel(
		Rect2(-24, 17, 12, 13),
		Color("#405965")
	)

	_armour_panel(
		Rect2(12, 17, 12, 13),
		Color("#405965")
	)

	draw_rect(
		Rect2(-21, 25, 6, 3),
		Color("#FFB885")
	)

	draw_rect(
		Rect2(15, 25, 6, 3),
		Color("#FFB885")
	)

	# Recessed turret mount.
	draw_circle(Vector2(0, -3), 14.0, Color("#14232D"))
	draw_circle(Vector2(0, -4), 11.0, Color("#94A7AF"))
	draw_circle(Vector2(0, -4), 8.0, Color("#304753"))

	# Armoured barrel, aligned with the existing muzzle.
	_armour_panel(
		Rect2(-6, -42, 12, 30),
		Color("#94A7AF")
	)

	draw_rect(
		Rect2(-8, -44, 16, 7),
		Color("#304753")
	)

	draw_rect(
		Rect2(-4, -44, 8, 3),
		Color("#101B23")
	)

	# Large optic remains identifiable at gameplay size.
	draw_circle(Vector2(0, 1), 6.0, Color("#14232D"))
	draw_circle(Vector2(0, 0), 4.0, Color("#FF9A8B"))
	draw_circle(Vector2(-1, -1), 1.5, Color("#FFE5D9"))

	# Shoulder vents.
	for vent_index in range(3):
		var vent_y := -7.0 + float(vent_index) * 6.0

		draw_rect(
			Rect2(-26, vent_y, 7, 2),
			Color("#243B47")
		)

		draw_rect(
			Rect2(19, vent_y, 7, 2),
			Color("#243B47")
		)

func _draw_interceptor() -> void:
	# Dark outer silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0, -35),
			Vector2(16, -14),
			Vector2(20, 16),
			Vector2(12, 30),
			Vector2(-12, 30),
			Vector2(-20, 16),
			Vector2(-16, -14),
		]),
		Color("#14232D")
	)

	# Raised central armour.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0, -31),
			Vector2(12, -12),
			Vector2(15, 14),
			Vector2(8, 24),
			Vector2(-8, 24),
			Vector2(-15, 14),
			Vector2(-12, -12),
		]),
		Color("#78909B")
	)

	# Split nose plates leave a dark centre seam.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-1, -29),
			Vector2(-10, -12),
			Vector2(-3, -6),
		]),
		Color("#A8B6BB")
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(1, -29),
			Vector2(10, -12),
			Vector2(3, -6),
		]),
		Color("#607B87")
	)

	# Engine pods give the rear a wider, powerful shape.
	_armour_panel(
		Rect2(-25, 4, 13, 28),
		Color("#607B87")
	)

	_armour_panel(
		Rect2(12, 4, 13, 28),
		Color("#607B87")
	)

	# Engine recesses and exhaust.
	draw_rect(Rect2(-22, 12, 7, 14), Color("#203642"))
	draw_rect(Rect2(15, 12, 7, 14), Color("#203642"))

	draw_rect(Rect2(-22, 27, 7, 4), Color("#FFBD8A"))
	draw_rect(Rect2(15, 27, 7, 4), Color("#FFBD8A"))

	# Central sensor housing.
	_armour_panel(
		Rect2(-8, -6, 16, 19),
		Color("#304753")
	)

	draw_rect(
		Rect2(-5, -3, 10, 5),
		Color("#FF9A8B")
	)

	draw_rect(
		Rect2(-3, -3, 6, 1),
		Color("#FFE5D9")
	)

	# Rear spine.
	draw_rect(
		Rect2(-3, 14, 6, 10),
		Color("#405965")
	)
func _armour_panel(rect: Rect2, face_color: Color) -> void:
	# Dark border and lower edge.
	draw_rect(rect, Color("#14232D"))
	
	var inset = rect.grow(-2.0)
	draw_rect(inset, face_color)
	
	# Hightlight across the upper edge.
	draw_line(
		inset.position,
		inset.position + Vector2(inset.size.x, 0),
		face_color.lightened(0.2),
		1.0
	)
