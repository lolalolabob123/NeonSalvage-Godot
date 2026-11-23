extends CanvasLayer

@onready var amount_label: Label = $SalvagePanel/Row/Amount
@onready var hull_amount: Label = $HullPanel/Row/Amount
@onready var hull_bar: ProgressBar = $HullBar
@onready var dash_amount: Label = $DashPanel/Row/Amount
@onready var banked_label: Label = $BankedLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var shield_panel: PanelContainer = $ShieldPanel
@onready var shield_amount: Label = $ShieldPanel/Row/Amount
@onready var system_title: Label = $ShieldPanel/Row/Title
@onready var cargo_panel: PanelContainer = $CargoPanel
@onready var cargo_equipment_list: Label = $CargoPanel/Content/EquipmentList

var player: Node = null
var pulse_tween: Tween
var hull_tween: Tween
var last_dash_text: String = ""
var cargo_mission: FacilityMission = null

func _ready() -> void:
	cargo_panel.hide()
	call_deferred("_connect_cargo_display")
	
	var system_id := ProgressStore.selected_system

	shield_panel.visible = (
		system_id == ProgressStore.SHIELD_GENERATOR_ID
		or system_id == ProgressStore.EMP_EMITTER_ID
	)

	if system_id == ProgressStore.EMP_EMITTER_ID:
		system_title.text = "EMP [Q]"
	else:
		system_title.text = "SHIELD [Q]"
	
	amount_label.text = "0"
	
	ProgressStore.banked_salvage_changed.connect(
		_on_banked_salvage_changed
	)
	_on_banked_salvage_changed(ProgressStore.banked_salvage)
	
	amount_label.add_theme_color_override(
		"font_color",
		Color("#F3AC57")
	)

	player = get_tree().get_first_node_in_group("player")

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


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	
	ammo_label.text = str(player.call("get_ammo_status_text"))
	
	if shield_panel.visible:
		_update_shield_status()
	
	var dash_text: String = str(
		player.call("get_dash_status_text")
	)

	# Only update when the displayed status changes.
	if dash_text == last_dash_text:
		return

	last_dash_text = dash_text
	dash_amount.text = dash_text

	var dash_color: Color

	if dash_text == "LOCKED":
		dash_color = Color("#758D99")

	elif dash_text == "READY":
		dash_color = Color("#31CBE0")

	else:
		dash_color = Color("#F3AC57")

	# Update the label colour.
	dash_amount.add_theme_color_override(
		"font_color",
		dash_color
	)


func _on_salvage_changed(total: int) -> void:
	amount_label.text = str(total)

	# Scale around the centre of the number.
	amount_label.pivot_offset = amount_label.size / 2.0

	# Stop an unfinished pulse.
	if pulse_tween != null and pulse_tween.is_running():
		pulse_tween.kill()

	amount_label.scale = Vector2.ONE

	pulse_tween = create_tween()

	# Quickly grow.
	pulse_tween.tween_property(
		amount_label,
		"scale",
		Vector2(1.22, 1.22),
		0.09
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_health_changed(current: int, maximum: int) -> void:
	hull_amount.text = "%d/%d" % [current, maximum]

	hull_bar.max_value = maximum

	# Stop the previous animation if one is running.
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

func _on_banked_salvage_changed(total: int) -> void:
	banked_label.text = "BANKED: %d" % total
	
	banked_label.add_theme_color_override(
		"font_color",
		Color("#31CBE0")
	)

func _update_shield_status() -> void:
	var active_time: float = 0.0
	var cooldown: float = 0.0

	if ProgressStore.selected_system == ProgressStore.EMP_EMITTER_ID:
		cooldown = float(player.get("emp_cooldown_remaining"))
	else:
		active_time = float(player.get("shield_time_remaining"))
		cooldown = float(player.get("shield_cooldown_remaining"))

	var status := "READY"
	var status_color := Color("#31CBE0")

	if active_time > 0.0:
		status = "ACTIVE"
		status_color = Color("#8CE8FF")
	elif cooldown > 0.0:
		status = "%.1fs" % (ceilf(cooldown * 10.0) / 10.0)
		status_color = Color("#F3AC57")

	if shield_amount.text != status:
		shield_amount.text = status

	if shield_amount.get_theme_color("font_color") != status_color:
		shield_amount.add_theme_color_override("font_color", status_color)

func _connect_cargo_display() -> void:
	cargo_mission = get_tree().get_first_node_in_group(
		"mission_controller"
	) as FacilityMission

	if not is_instance_valid(cargo_mission):
		cargo_panel.hide()
		return

	cargo_mission.mission_stage_changed.connect(
		_refresh_cargo_display
	)
	cargo_mission.mission_completed.connect(
		_refresh_cargo_display
	)

	_refresh_cargo_display()


func _refresh_cargo_display() -> void:
	if not is_instance_valid(cargo_mission):
		cargo_panel.hide()
		return

	if cargo_mission.extraction_complete:
		cargo_panel.hide()
		return

	var lines := PackedStringArray()

	for gear_id in cargo_mission.unsecured_gear:
		var equipment := ProgressStore.get_equipment(gear_id)

		if equipment == null:
			continue

		lines.append(
			"%s — unsecured" % equipment.display_name
		)
	
	cargo_equipment_list.text = "\n".join(lines)
	cargo_panel.visible = not lines.is_empty()
