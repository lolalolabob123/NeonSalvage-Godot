extends Area2D

@onready var pickup_sprite: Sprite2D = $Sprite2D

var salvage_amount: int = 1

func _ready() -> void:
	monitoring = false
	
	body_entered.connect(_on_body_entered)
	
	# Gentle floating animation.
	var hover: Tween = create_tween().set_loops()
	hover.set_trans(Tween.TRANS_SINE)
	hover.set_ease(Tween.EASE_IN_OUT)
	
	hover.tween_property(
		pickup_sprite,
		"position:y",
		-3.0,
		0.65
	)
	
	hover.tween_property(
		pickup_sprite,
		"position:y",
		3.0,
		0.65
	)
	
	await get_tree().create_timer(0.15).timeout
	monitoring = true

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	if not body.has_method("add_salvage"):
		return
	
	body.add_salvage(salvage_amount)
	queue_free()
