extends Area2D
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	
	for body in get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue
		
		if int(body.get("current_health")) <= 0:
			continue
		
		var mission := get_tree().get_first_node_in_group(
			"mission_controller"
		) as FacilityMission
	
		if not is_instance_valid(mission):
			return
		
		if mission.recover_prototype():
			get_viewport().set_input_as_handled()
			queue_free()
		
		return
