extends CanvasLayer

@onready var amount_label: Label = $SalvagePanel/Row/Amount

var pulse_tween: Tween

func _ready() -> void:
	amount_label.text = "0"
	
	var player: Node = get_tree().get_first_node_in_group("player")
	
	if player == null:
		push_warning("SalvageHUD: Player not found.")
		return
	
	player.connect("salvage_changed", _on_salvage_changed)
	
	# Display the player's current total immediately.
	amount_label.text = str(int(player.get("salvage_total")))

func _on_salvage_changed(total: int) -> void:
	amount_label.text = str(total)
	
	# Scale around the centre of the number.
	amount_label.pivot_offset = amount_label.size / 2.0
	
	# Stop an unfinished pulse
	if pulse_tween != null and pulse_tween.is_running():
		pulse_tween.kill()
	
	amount_label.scale = Vector2.ONE
	
	pulse_tween = create_tween()
	
	# Quickly grow
	pulse_tween.tween_property(
		amount_label,
		"scale",
		Vector2(1.22, 1.22),
		0.09
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
