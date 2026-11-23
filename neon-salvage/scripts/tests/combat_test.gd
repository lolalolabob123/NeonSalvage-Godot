extends Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	if event.physical_keycode != KEY_T:
		return

	get_viewport().set_input_as_handled()
	get_tree().paused = false

	var error := get_tree().reload_current_scene()

	if error != OK:
		push_error(
			"Could not restart combat test: %s"
			% error_string(error)
		)
