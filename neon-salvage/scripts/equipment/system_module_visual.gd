@tool
extends Node2D

enum ModuleStyle {
	SHIELD,
	EMP,
}

@export var module_style: ModuleStyle = ModuleStyle.SHIELD:
	set(value):
		module_style = value
		queue_redraw()

func _draw() -> void:
	# Shared mounting plate.
	draw_rect(
		Rect2(-22, -16, 44, 32),
		Color("#142733")
	)
	draw_rect(
		Rect2(-22, -16, 44, 32),
		Color("#567583"),
		false,
		2.0
	)
	
	match module_style:
		ModuleStyle.SHIELD:
			_draw_shield_module()
		
		ModuleStyle.EMP:
			_draw_emp_module()

func _draw_shield_module() -> void:
	var shield_shape := PackedVector2Array([
		Vector2(-13, -10),
		Vector2(13, -10),
		Vector2(11, 5),
		Vector2(0, 13),
		Vector2(-11, 5),
	])
	
	draw_colored_polygon(
		shield_shape,
		Color("#31CBE0")
	)
	
	draw_rect(
		Rect2(-4, -6, 8, 13),
		Color("B6F5FF")
	)

func _draw_emp_module() -> void:
	# Two capacitor banks around a bright central core.
	draw_rect(
		Rect2(-16, -10, 9, 20),
		Color("A785E8")
	)
	draw_rect(
		Rect2(7, -10, 9, 20),
		Color("#A785E8")
	)
	
	draw_circle(
		Vector2.ZERO,
		6.0,
		Color("D8C6FF")
	)
	
	draw_line(
		Vector2(-16, 0),
		Vector2(16, 0),
		Color("#FFFFFF"),
		2.0
	)
