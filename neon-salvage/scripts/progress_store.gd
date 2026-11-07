extends Node

signal banked_salvage_changed(total: int)

const SAVE_PATH: String = "user://neon_salvage_progress.cfg"

var banked_salvage: int = 0
var storage_available: bool = true

var save_data: ConfigFile = ConfigFile.new()


func _ready() -> void:
	var error := save_data.load(SAVE_PATH)

	# A new player doesn't have a save file yet.
	if error == ERR_FILE_NOT_FOUND:
		return

	if error != OK:
		storage_available = false
		push_error("Could not load saved progress: %s" % error_string(error))
		return

	var saved_total: Variant = save_data.get_value(
		"progress", "banked_salvage", 0
	)

	if typeof(saved_total) != TYPE_INT:
		storage_available = false
		push_error("Saved salvage balance is invalid.")
		return

	if saved_total < 0:
		storage_available = false
		push_error("Saved salvage balance is negative.")
		return

	banked_salvage = int(saved_total)


func bank_salvage(amount: int) -> bool:
	if not storage_available or amount < 0:
		return false

	var new_total: int = banked_salvage + amount

	save_data.set_value("progress", "banked_salvage", new_total)

	var error := save_data.save(SAVE_PATH)

	if error != OK:
		save_data.set_value("progress", "banked_salvage", banked_salvage)
		push_error("Could not save progress: %s" % error_string(error))
		return false

	banked_salvage = new_total
	banked_salvage_changed.emit(banked_salvage)
	return true
