@tool
extends Node2D

const HORIZONTAL: Texture2D = preload(
	"res://assets/environment/ScientificWall_Straight256.png"
)
const VERTICAL: Texture2D = preload(
	"res://assets/environment/ScientificWall_Vertical256.png"
)
const CORNER: Texture2D = preload(
	"res://assets/environment/ScientificWall_CornerNorthEast.png"
)

const CORNER_DOWN: Texture2D = preload(
	"res://assets/environment/ScientificWall_CornerSouthEast.png"
)

@onready var wall: Node2D = get_parent() as Node2D

var last_settings: Array = []


func _ready() -> void:
	_refresh()


func _process(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	if not is_instance_valid(wall):
		return

	var size: Vector2 = wall.get("wall_size")
	var enabled: bool = wall.get("use_modular_art") == true
	var horizontal := size.x >= size.y
	var length := size.x if horizontal else size.y

	# Codes: 0 none, 1 NE, 2 SE, 3 NW, 4 SW.
	var first_corner: int = 0
	var last_corner: int = 0

	if horizontal:
		if wall.get("left_turns_up") == true:
			first_corner = 1
		elif wall.get("left_turns_down") == true:
			first_corner = 2

		if wall.get("right_turns_up") == true:
			last_corner = 3
		elif wall.get("right_turns_down") == true:
			last_corner = 4
	else:
		if wall.get("top_turns_right") == true:
			first_corner = 2
		elif wall.get("top_turns_left") == true:
			first_corner = 4

		if wall.get("bottom_turns_right") == true:
			last_corner = 1
		elif wall.get("bottom_turns_left") == true:
			last_corner = 3

	var reserved: float = 0.0
	if first_corner != 0:
		reserved += 80.0
	if last_corner != 0:
		reserved += 80.0

	if reserved > length:
		first_corner = 0
		last_corner = 0

	var settings: Array = [
		size, enabled, first_corner, last_corner
	]

	if settings == last_settings:
		return

	last_settings = settings
	visible = enabled

	for child in get_children():
		remove_child(child)
		child.queue_free()

	if not enabled:
		return

	var start := -size * 0.5
	var axis := Vector2.RIGHT if horizontal else Vector2.DOWN
	var run_start := start
	var run_length := length

	if first_corner != 0:
		_add_corner(first_corner, start)
		run_start += axis * 80.0
		run_length -= 80.0

	if last_corner != 0:
		_add_corner(
			last_corner,
			start + axis * (length - 80.0)
		)
		run_length -= 80.0

	var distance: float = 0.0

	while distance < run_length:
		var section_length := minf(
			256.0, run_length - distance
		)

		if horizontal:
			_add_piece(
				HORIZONTAL,
				run_start + axis * distance,
				Vector2(section_length, 80.0)
			)
		else:
			_add_piece(
				VERTICAL,
				run_start + axis * distance,
				Vector2(80.0, section_length)
			)

		distance += section_length
func _add_piece(
	image: Texture2D,
	at_position: Vector2,
	region_size: Vector2,
	mirror: bool = false
) -> void:
	var piece := Sprite2D.new()
	piece.texture = image
	piece.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	piece.centered = false
	piece.region_enabled = true
	piece.region_filter_clip_enabled = true
	piece.region_rect = Rect2(Vector2(16.0, 16.0), region_size)
	piece.position = at_position
	piece.flip_h = mirror
	add_child(piece)

func _add_corner(code: int, at_position: Vector2) -> void:
	var faces_down := code == 2 or code == 4
	var mirrored := code == 3 or code == 4

	_add_piece(
		CORNER_DOWN if faces_down else CORNER,
		at_position,
		Vector2(80.0, 80.0),
		mirrored
	)
