@tool
extends Node2D

@export var west_end: Node2D
@export var east_end: Node2D
@export var corridor_wall: Node2D
@export var below_corridor: bool = false

const WALL_OFFSET := 48.0
const BEAM_SPACING := 28.0
const BRACE_SPACING := 96.0
const BEAM_COLOR := Color("#18293B")
const BRACE_COLOR := Color("#122030")

var beam_bounds := Rect2()

func _ready() -> void:
	_update_bounds()
	set_process(Engine.is_editor_hint())

func _process(_delta: float) -> void:
	_update_bounds()

func _update_bounds() -> void:
	var bounds := Rect2()
	
	if (
		is_instance_valid(west_end)
		and is_instance_valid(east_end)
		and is_instance_valid(corridor_wall)
	):
		var left := to_local(west_end.global_position).x
		var right := to_local(east_end.global_position).x
		var wall_y := to_local(corridor_wall.global_position).y
		if right > left:
			var top := wall_y - WALL_OFFSET - BEAM_SPACING
			if below_corridor:
				top = wall_y + WALL_OFFSET
			bounds = Rect2(left, top, right - left, BEAM_SPACING)

	if bounds != beam_bounds:
		beam_bounds = bounds
		queue_redraw()

func _draw() -> void:
	if not beam_bounds.has_area():
		return
	
	var top_left := beam_bounds.position
	var bottom_left := top_left + Vector2(0.0, beam_bounds.size.y)
	var span := Vector2(beam_bounds.size.x, 0.0)
	
	var sections := ceili(span.x / BRACE_SPACING)
	for i in range(1, sections):
		var offset := span * (float(i) / sections)
		draw_line(top_left + offset, bottom_left + offset, BRACE_COLOR, 6.0)
	
	draw_line(top_left, top_left + span, BEAM_COLOR, 12.0)
	draw_line(bottom_left, bottom_left + span, BEAM_COLOR, 12.0)
