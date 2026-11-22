extends Button

@export var equipment_slot: EquipmentDefinition.Slot = (
	EquipmentDefinition.Slot.PRIMARY_WEAPON
)

var drop_feedback: int = 0

func _is_equipment_drag(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	
	if data.get("drag_type") != &"drone_equipment":
		return false
	
	var equipment_id: Variant = data.get("equipment_id")
	
	return (
		typeof(equipment_id) == TYPE_STRING_NAME
		or typeof(equipment_id) == TYPE_STRING
	)

func _can_drop_data(
	_at_position: Vector2,
	data: Variant
) -> bool:
	if not _is_equipment_drag(data):
		return false
	
	var equipment_id := StringName(data["equipment_id"])
	
	if equipment_id == &"":
		return false
	
	return ProgressStore.can_equip_equipment(
		equipment_id,
		equipment_slot
	)

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return

	ProgressStore.equip_equipment(
		StringName(data["equipment_id"]),
		equipment_slot
	)
func _process(_delta: float) -> void:
	var next_feedback := 0
	var viewport := get_viewport()
	
	if is_visible_in_tree() and viewport.gui_is_dragging():
		var data: Variant = viewport.gui_get_drag_data()
		
		if _is_equipment_drag(data):
			if _can_drop_data(Vector2.ZERO, data):
				next_feedback = 1
			elif Rect2(Vector2.ZERO, size).has_point(
				get_local_mouse_position()
			):
				next_feedback = -1
	
	if next_feedback != drop_feedback:
		drop_feedback = next_feedback
		queue_redraw()

func _draw() -> void:
	if drop_feedback == 0:
		return
	
	var border_color := Color("#31CBE0")
	
	if drop_feedback < 0:
		border_color = Color("#F25768")
	
	draw_rect(
		Rect2(
			Vector2(2, 2),
			size - Vector2(4, 4)
		),
		border_color,
		false,
		2.0
	)
