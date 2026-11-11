@tool
extends Control

const LINE_COLOR := Color("#3F697A")
const LINE_WIDTH := 2.0

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var center_x := size.x * 0.5
	var left_x := size.x * 0.25
	var right_x := size.x * 0.75
	var middle_y := size.y * 0.5
	
	draw_line(Vector2(center_x, 0), Vector2(center_x, middle_y), LINE_COLOR, LINE_WIDTH)
	draw_line(Vector2(left_x, middle_y), Vector2(right_x, middle_y), LINE_COLOR, LINE_WIDTH)
	draw_line(Vector2(left_x, middle_y), Vector2(left_x, size.y), LINE_COLOR, LINE_WIDTH)
	draw_line(Vector2(right_x, middle_y), Vector2(right_x, size.y), LINE_COLOR, LINE_WIDTH)
