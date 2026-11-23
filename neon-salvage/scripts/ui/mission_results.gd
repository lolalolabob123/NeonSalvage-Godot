extends CanvasLayer

@export var mission_controller: FacilityMission

@onready var overlay: ColorRect = $Overlay
@onready var restart_button: Button = $Overlay/Center/Panel/Margin/Content/RestartButton
@onready var details_label: Label = $Overlay/Center/Panel/Margin/Content/DetailsLabel

func _ready() -> void:
	overlay.hide()
	restart_button.pressed.connect(_restart_mission)
	
	if not is_instance_valid(mission_controller):
		push_error("MissionResults needs a MissionController.")
		return
	
	mission_controller.mission_completed.connect(
		_show_results
	)

func _show_results() -> void:
	var outcome := "Main objective incomplete. Carried loot secured."

	if mission_controller.objective_completed_on_extraction:
		outcome = "Main objective complete. Carried loot secured."

	details_label.text = (
		outcome
		+ "\nSalvage banked this run: %d"
		+ "\nTotal banked salvage: %d"
	) % [
		mission_controller.extracted_salvage,
		ProgressStore.banked_salvage
	]
	
	for gear_id in mission_controller.secured_gear_this_run:
		var equipment := ProgressStore.get_equipment(gear_id)

		if equipment == null:
			continue

		details_label.text += "\n\n%s secured." % (
			equipment.display_name
		)

	overlay.show()
	restart_button.grab_focus()

func _restart_mission() -> void:
	get_tree().paused = false
	
	var error := get_tree().change_scene_to_file("res://scenes/ui/PreperationScreen.tscn")
	
	if error != OK:
		get_tree().PAUSED = true
		push_error("Could not return to preperation: %S" % error_string(error))
