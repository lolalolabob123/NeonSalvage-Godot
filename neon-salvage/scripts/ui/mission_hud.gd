extends CanvasLayer

@export var mission_controller: FacilityMission
@export var show_security_card_objective: bool = false

@onready var objective_label: Label = $ObjectiveLabel


func _ready() -> void:
	if not is_instance_valid(mission_controller):
		objective_label.text = "Mission controller not assigned."
		return

	mission_controller.prototype_recovered.connect(_update_objective)
	mission_controller.power_restored.connect(_update_objective)
	mission_controller.extraction_called.connect(_update_objective)
	mission_controller.transport_arrived.connect(_update_objective)
	mission_controller.mission_completed.connect(_update_objective)
	mission_controller.security_card_collected.connect(_update_objective)
	mission_controller.mission_stage_changed.connect(_update_objective)

	_update_objective()


func _process(_delta: float) -> void:
	if not is_instance_valid(mission_controller):
		return

	if (
		mission_controller.has_called_extraction
		and not mission_controller.transport_ready
	):
		_update_objective()


func _update_objective() -> void:
	objective_label.modulate = Color("#31CBE0")

	if mission_controller.extraction_complete:
		if mission_controller.objective_completed_on_extraction:
			objective_label.text = (
				"EXTRACTION SUCCESSFUL\n"
				+ "Main objective complete. Loot secured."
			)
		else:
			objective_label.text = (
				"EXTRACTION SUCCESSFUL\n"
				+ "Main objective incomplete. Loot secured."
			)

	elif mission_controller.transport_ready:
		objective_label.text = (
            "TRANSPORT READY\n"
			+ "Return to the Dock extraction terminal."
		)

	elif mission_controller.has_called_extraction:
		var seconds := ceili(mission_controller.extraction_time_left)
		var heading := "EXTRACTION INBOUND"

		if mission_controller.extraction_response_suppressed:
			heading += " — RESPONSE DISABLED"
		else:
			heading += " — SECURITY ALERT"

		objective_label.text = (
			heading
			+ "\nTransport arrives in %d seconds." % seconds
		)
		objective_label.modulate = Color("#F3AC57")

	elif mission_controller.is_objective_complete():
		objective_label.text = (
			mission_controller.get_objective_complete_text()
			+ "\nReturn to the extraction terminal."
		)
		objective_label.modulate = Color("#F3AC57")

	elif (
		show_security_card_objective
		and not mission_controller.has_security_card
	):
		objective_label.text = (
            "OBJECTIVE\n"
			+ "Find the security access card in the entry room."
		)

	else:
		objective_label.text = (
            "OBJECTIVE\n"
			+ mission_controller.get_objective_instruction()
		)
