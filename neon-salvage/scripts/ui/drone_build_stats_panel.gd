extends PanelContainer

@onready var stats_label: Label = $Margin/StatsLabel


func _ready() -> void:
	ProgressStore.loadout_changed.connect(_refresh)

	ProgressStore.banked_salvage_changed.connect(
		_on_balance_changed
	)

	_refresh()


func _on_balance_changed(_total: int) -> void:
	_refresh()


func _refresh() -> void:
	var stats := DroneBuildStats.calculate()

	var weapon := ProgressStore.selected_primary_weapon

	if weapon == null:
		var starter_weapon := ProgressStore.get_equipment(&"carbine")

		if starter_weapon != null:
			weapon = starter_weapon.weapon_definition

	var weapon_summary := "Weapon: None"

	if weapon != null:
		weapon_summary = "%s: %d rounds / %.1fs reload" % [
			weapon.display_name,
			weapon.magazine_capacity,
			weapon.reload_duration,
		]

	stats_label.text = (
		"BUILD STATS\n"
		+ "Maximum hull: %d\n"
		+ "Movement speed: %.0f px/s\n"
		+ "Dash: ~%.0f px / %.1fs cooldown\n"
		+ "%s\n"
		+ "%s"
	) % [
		int(stats["maximum_hull"]),
		float(stats["movement_speed"]),
		float(stats["dash_distance"]),
		float(stats["dash_cooldown"]),
		weapon_summary,
		DroneBuildStats.get_system_summary(),
	]
