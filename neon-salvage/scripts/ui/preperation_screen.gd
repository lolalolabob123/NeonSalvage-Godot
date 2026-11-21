extends Control

@export var mission_scene: PackedScene
@export var relay_station_scene: PackedScene

@onready var preparation_view: CenterContainer = $Center
@onready var upgrades_view: CenterContainer = $UpgradesView
@onready var banked_label: Label = $Center/Panel/Margin/Content/BankedLabel
@onready var deploy_button: Button = $Center/Panel/Margin/Content/DeployButton
@onready var upgrades_button: Button = $Center/Panel/Margin/Content/UpgradesButton
@onready var upgrades_banked_label: Label = $UpgradesView/Panel/Margin/Content/UpgradesBankedLabel
@onready var upgrade_status: Label = $UpgradesView/Panel/Margin/Content/SkillTree/UpgradeStatus
@onready var back_button: Button = $UpgradesView/Panel/Margin/Content/BackButton
@onready var reset_skills_button: Button = $UpgradesView/Panel/Margin/Content/ResetSkillsButton
@onready var loadout_view: CenterContainer = $LoadoutView
@onready var loadout_button: Button = $Center/Panel/Margin/Content/LoadoutButton
@onready var loadout_back_button: Button = $LoadoutView/Panel/Margin/Content/LoadoutBackButton
@onready var mission_selector: OptionButton = $Center/Panel/Margin/Content/MissionSelector
@onready var mission_briefing: Label = $Center/Panel/Margin/Content/MissionBriefingLabel
@onready var gear_inventory: DroneGearInventory = $LoadoutView/Panel/Margin/Content/Body/SlotInspector/GearInventory
@onready var weapon_slot: Button = $LoadoutView/Panel/Margin/Content/Body/DroneSchematic/WeaponSlot
@onready var system_slot: Button = $LoadoutView/Panel/Margin/Content/Body/DroneSchematic/SystemSlot

func _ready() -> void:
	upgrades_view.hide()
	loadout_view.hide()

	_update_bank_balance(ProgressStore.banked_salvage)
	ProgressStore.banked_salvage_changed.connect(_update_bank_balance)

	deploy_button.pressed.connect(_deploy)
	upgrades_button.pressed.connect(_open_upgrades)
	back_button.pressed.connect(_close_upgrades)

	reset_skills_button.visible = OS.is_debug_build()
	reset_skills_button.pressed.connect(_reset_skills)

	loadout_button.pressed.connect(_open_loadout)
	loadout_back_button.pressed.connect(_close_loadout)

	mission_selector.clear()
	mission_selector.add_item("Blacksite 7 - Introduction")
	mission_selector.add_item("Relay Station - Power Recovery")

	var mission_index := clampi(
		ProgressStore.selected_mission_index,
		0,
		1
	)

	mission_selector.select(mission_index)
	mission_selector.item_selected.connect(_on_mission_selected)
	_on_mission_selected(mission_index)
	
	weapon_slot.pressed.connect(
		_select_loadout_slot.bind(&"weapon")
	)
	system_slot.pressed.connect(
		_select_loadout_slot.bind(&"system")
	)
	
	gear_inventory.loadout_changed.connect(_update_slot_labels)
	
	_select_loadout_slot(&"weapon")

func _update_bank_balance(total: int) -> void:
	banked_label.text = "Banked salvage: %d" % total
	upgrades_banked_label.text = banked_label.text

	var hull_bonus := 0
	if ProgressStore.has_skill(ProgressStore.HULL_REINFORCEMENT_ID):
		hull_bonus += 1
	if ProgressStore.has_skill(ProgressStore.HULL_REINFORCEMENT_II_ID):
		hull_bonus += 1

	upgrade_status.visible = hull_bonus > 0
	upgrade_status.text = "Total bonus: +%d maximum hull." % hull_bonus


func _deploy() -> void:
	var selected_scene := _get_selected_mission_scene()

	if selected_scene == null:
		push_error("The selected mission needs its scene assigned.")
		return

	# Only owned equipment can occupy the active system slot.
	var system_id := ProgressStore.selected_system

	if system_id != &"" and not ProgressStore.owns_gear(system_id):
		ProgressStore.selected_system = &""

	deploy_button.disabled = true
	get_tree().paused = false

	var error := get_tree().change_scene_to_packed(selected_scene)

	if error != OK:
		deploy_button.disabled = false
		push_error("Could not deploy: %s" % error_string(error))

func _open_upgrades() -> void:
	preparation_view.hide()
	upgrades_view.show()
	_focus_upgrade_action()

func _focus_upgrade_action() -> void:
	for node in upgrades_view.find_children("PurchaseButton", "Button", true, false):
		var button := node as Button
		if button.is_visible_in_tree() and not button.disabled:
			button.grab_focus()
			return
	
	back_button.grab_focus()

func _close_upgrades() -> void:
	upgrades_view.hide()
	preparation_view.show()
	upgrades_button.grab_focus()

func _reset_skills() -> void:
	if ProgressStore.reset_skills_for_testing():
		reset_skills_button.text = "Reset Skills (Debug)"
	else:
		reset_skills_button.text = "Reset failed. Try again."

func _open_loadout() -> void:
	preparation_view.hide()
	loadout_view.show()
	
	_select_loadout_slot(&"weapon")
	weapon_slot.grab_focus()

func _close_loadout() -> void:
	loadout_view.hide()
	preparation_view.show()
	loadout_button.grab_focus()

func _on_mission_selected(index: int) -> void:
	ProgressStore.selected_mission_index = index
	
	match index:
		0:
			var reward_text := "Optional reward: Shield Generator."
			
			if ProgressStore.owns_shield_generator():
				reward_text = "Shield Generator already secured."
			
			mission_briefing.text = (
				"BLACKSITE 7\n\n"
				+ "Recover the prototype and return to the entry terminal.\n"
				+ "Calling extraction triggers a security response.\n\n"
				+ "Explore Salvage Storage for extra loot.\n"
				+ reward_text
				+ "\nExtract successfully to bank carried loot."
			)
			
			deploy_button.text = "Deploy to Blacksite 7"
			
		1:
			var reward_text := "Research reward: EMP Emitter."
			
			if ProgressStore.owns_gear(ProgressStore.EMP_EMITTER_ID):
				reward_text = "Research reward: 10-salvage cache."
			
			mission_briefing.text = (
				"RELAY STATION\n\n"
				+ "Restart the turbine to unlock Research Annex.\n"
				+ "Maintenance can disable electrical hazards.\n\n"
				+ "Security Control can disable extraction reinforcements.\n\n"
				+ reward_text
				+ "\nExplore Processing vault for additional salvage."
				+ "\nYou may extract early with carried loot."
			)
			
			deploy_button.text = "Deploy to Relay Station"
	
	var selected_scene := _get_selected_mission_scene()
	deploy_button.disabled = selected_scene == null
	
	if selected_scene == null:
		mission_briefing.text += "\n\nMission scene has not been assigned."

func _get_selected_mission_scene() -> PackedScene:
	if mission_selector.selected == 1:
		return relay_station_scene
	
	return mission_scene

func _select_loadout_slot(slot_id: StringName) -> void:
	var selecting_weapon := slot_id == &"weapon"
	
	weapon_slot.set_pressed_no_signal(selecting_weapon)
	system_slot.set_pressed_no_signal(not selecting_weapon)
	
	gear_inventory.select_slot(slot_id)
	_update_slot_labels()

func _update_slot_labels() -> void:
	var weapon_name := "None"
	var weapon := ProgressStore.selected_primary_weapon
	
	if weapon != null:
		weapon_name = weapon.display_name
	
	weapon_slot.text = "PRIMARY WEAPON\n%s" % weapon_name
	
	var system_name = "None"
	var system_id := ProgressStore.selected_system
	
	if ProgressStore.owns_gear(system_id):
		var gear: Dictionary = ProgressStore.GEAR[system_id]
		system_name = gear["display_name"]
	
	system_slot.text = "ACTIVE SYSTEM\n%s" % system_name
