extends Area2D
func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	if int(body.get("current_health")) <= 0:
		return
	
	var mission := get_tree().get_first_node_in_group(
		"mission_controller"
	) as FacilityMission
	
	if not is_instance_valid(mission):
		return
	
	mission.collect_security_card()
	
	queue_free()
