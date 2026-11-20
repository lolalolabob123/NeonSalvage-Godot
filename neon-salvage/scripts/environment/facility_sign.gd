@tool
extends Node2D

@export var heading: String = "FACILITY":
	set(value):
		heading = value
		_refresh()

@export_multiline var details: String = "Direction or room information":
	set(value):
		details = value
		_refresh()

@export_range(160.0, 700.0, 10.0) var sign_width: float = 400.0:
	set(value):
		sign_width = value
		_refresh()

@export var heading_color: Color = Color("#8EB8C5"):
	set(value):
		heading_color = value
		_refresh()

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	var heading_label := get_node_or_null("Heading") as Label
	var details_label := get_node_or_null("Details") as Label
	
	if heading_label == null or details_label == null:
		return
	
	heading_label.text = heading
	heading_label.position = Vector2(-sign_width * 0.5, 0.0)
	heading_label.size = Vector2(sign_width, 34.0)
	heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading_label.add_theme_font_size_override("font_size", 24)
	heading_label.add_theme_color_override(
		"font_color", heading_color
	)
	
	details_label.text = details
	details_label.position = Vector2(-sign_width * 0.5, 38.0)
	details_label.size = Vector2(sign_width, 100.0)
	details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details_label.add_theme_font_size_override("font_size", 18)
	details_label.add_theme_color_override(
		"font_color", Color("#7895A1")
	)
