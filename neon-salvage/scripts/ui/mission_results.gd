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
	details_label.text = (
		"Prototype extracted.\n"
		+ "Salvage banked this run: %d\n"
		+ "Total banked salvage: %d"
	) % [
		mission_controller.extracted_salvage,
		ProgressStore.banked_salvage
	]

	overlay.show()
	restart_button.grab_focus()

func _restart_mission() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
