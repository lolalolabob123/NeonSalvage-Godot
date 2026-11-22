extends ItemList

var pressed_equipment_id: StringName = &""


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	pressed_equipment_id = &""

	if not event.pressed:
		return

	# Capture the item before selection can change the layout.
	var index := get_item_at_position(event.position, true)

	if index < 0 or is_item_disabled(index):
		return

	var metadata: Variant = get_item_metadata(index)

	if (
		typeof(metadata) == TYPE_STRING_NAME
		or typeof(metadata) == TYPE_STRING
	):
		pressed_equipment_id = StringName(metadata)


func _get_drag_data(_at_position: Vector2) -> Variant:
	var equipment_id := pressed_equipment_id

	if equipment_id == &"":
		return null

	if not ProgressStore.owns_equipment(equipment_id):
		return null

	var equipment := ProgressStore.get_equipment(equipment_id)

	if equipment == null:
		return null

	var preview := PanelContainer.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text = equipment.display_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 16)

	preview.add_child(label)
	set_drag_preview(preview)

	return {
		"drag_type": &"drone_equipment",
		"equipment_id": equipment_id,
	}
