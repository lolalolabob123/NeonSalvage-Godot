extends CanvasLayer

@onready var amount_label: Label = $SalvagePanel/Row/Amount
@onready var hull_amount: Label = $HullPanel/Row/Amount
@onready var hull_bar: ProgressBar = $HullBar

var pulse_tween: Tween
var hull_tween: Tween

func _ready() -> void:
	amount_label.text = "0"
	
	var player: Node = get_tree().get_first_node_in_group("player")
	
	if player == null:
		push_warning("SalvageHUD: Player not found.")
		return
	
	player.connect("salvage_changed", _on_salvage_changed)
	player.connect("health_changed", _on_health_changed)
	
	_on_health_changed(
		player.get("current_health"),
		player.get("max_health")
	)
	
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

func _on_health_changed(current: int, maximum: int) -> void:
	hull_amount.text = "%d/%d" % [current, maximum]
	
	hull_bar.max_value = maximum
	
	#Stop the previous animation if one is running.
	if hull_tween:
		hull_tween.kill()
		
	# Animate the health bar towards its new value.
	hull_tween = create_tween()
	
	hull_tween.tween_property(
		hull_bar,
		"value",
		float(current),
		0.22	
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Calculate the remaining health percentage.
	var health_ratio: float = float(current) / float(maxi(maximum, 1))
	
	# Copy the existing fill style to preserve its appearance.
	var fill_style: StyleBoxFlat = (
		hull_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	)
	
	# Choose a colour based on remaining health.
	if health_ratio > 0.6:
		fill_style.bg_color = Color("#31CBE0")
	elif health_ratio > 0.2:
		fill_style.bg_color = Color("#F3AC57")
	else:
		fill_style.bg_color = Color("#F25768")
	
	# Apply the updated colour.
	hull_bar.add_theme_stylebox_override("fill", fill_style)
