extends CanvasLayer

@export var mission_controller: FacilityMission

@onready var objective_label: Label = $ObjectiveLabel

func _ready() -> void:
	if not is_instance_valid(mission_controller):
		objective_label.text = "Mission controller not assigned."
		return
	
	mission_controller.prototype_recovered.connect(
		_update_objective
	)
	
	mission_controller.extraction_called.connect(
		_update_objective
	)
	
	mission_controller.transport_arrived.connect(
		_update_objective
	)
	
	mission_controller.mission_completed.connect(
		_update_objective
	)
	
	_update_objective()

func _update_objective() -> void:
	if mission_controller.extraction_complete:
		objective_label.text = (
			"EXTRACTION SUCCESSFUL\n"
			+ "Prototype extracted."
		)
		objective_label.modulate = Color("#31CBE0")

	elif mission_controller.transport_ready:
		objective_label.text = (
			"TRANSPORT READY\n"
			+ "Return to the extraction terminal."
		)
		objective_label.modulate = Color("#31CBE0")

	elif mission_controller.has_called_extraction:
		var seconds := ceili(mission_controller.extraction_time_left)

		objective_label.text = (
			"EXTRACTION INBOUND\n"
			+ "Transport arrives in %d seconds." % seconds
		)
		objective_label.modulate = Color("#F3AC57")

	elif mission_controller.has_prototype:
		objective_label.text = (
			"PROTOTYPE RECOVERED\n"
			+ "Return to the entry room."
		)
		objective_label.modulate = Color("#F3AC57")

	else:
		objective_label.text = (
			"OBJECTIVE\n"
			+ "Recover the prototype in the security room."
		)
		objective_label.modulate = Color("#31CBE0")

func _process(_delta: float) -> void:
	if not is_instance_valid(mission_controller):
		return
	
	if mission_controller.has_called_extraction:
		if not mission_controller.transport_ready:
			_update_objective()
