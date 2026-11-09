extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	if int(body.get("current_health")) <= 0:
		return
	
	body.set("dash_unlocked", true)
	queue_free()
