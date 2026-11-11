extends Control

const CARBINE: WeaponDefinition = preload("res://resources/weapons/Carbine.tres")
const SHOTGUN: WeaponDefinition = preload("res://resources/weapons/Shotgun.tres")

@export var mission_scene: PackedScene

@onready var preparation_view: CenterContainer = $Center
@onready var upgrades_view: CenterContainer = $UpgradesView
@onready var banked_label: Label = $Center/Panel/Margin/Content/BankedLabel
@onready var deploy_button: Button = $Center/Panel/Margin/Content/DeployButton
@onready var upgrades_button: Button = $Center/Panel/Margin/Content/UpgradesButton
@onready var primary_weapon_selector: OptionButton = $Center/Panel/Margin/Content/PrimaryWeaponSelector
@onready var weapon_description: Label = $Center/Panel/Margin/Content/WeaponDescription
@onready var upgrades_banked_label: Label = $UpgradesView/Panel/Margin/Content/UpgradesBankedLabel
@onready var upgrade_status: Label = $UpgradesView/Panel/Margin/Content/SkillTree/UpgradeStatus
@onready var back_button: Button = $UpgradesView/Panel/Margin/Content/BackButton
@onready var reset_skills_button: Button = $UpgradesView/Panel/Margin/Content/ResetSkillsButton


func _ready() -> void:
	upgrades_view.hide()
	_update_bank_balance(ProgressStore.banked_salvage)
	ProgressStore.banked_salvage_changed.connect(_update_bank_balance)

	deploy_button.pressed.connect(_deploy)
	upgrades_button.pressed.connect(_open_upgrades)
	back_button.pressed.connect(_close_upgrades)
	reset_skills_button.visible = OS.is_debug_build()
	reset_skills_button.pressed.connect(_reset_skills)

	primary_weapon_selector.clear()
	primary_weapon_selector.add_item(CARBINE.display_name)
	primary_weapon_selector.add_item(SHOTGUN.display_name)

	if ProgressStore.selected_primary_weapon == SHOTGUN:
		primary_weapon_selector.select(1)
	else:
		primary_weapon_selector.select(0)

	primary_weapon_selector.item_selected.connect(_update_weapon_description)
	_update_weapon_description(primary_weapon_selector.selected)


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
	if mission_scene == null:
		push_error("Preparation screen needs its Mission Scene assigned.")
		return

	if primary_weapon_selector.selected == 1:
		ProgressStore.selected_primary_weapon = SHOTGUN
	else:
		ProgressStore.selected_primary_weapon = CARBINE

	deploy_button.disabled = true
	get_tree().paused = false

	var error := get_tree().change_scene_to_packed(mission_scene)
	if error != OK:
		deploy_button.disabled = false
		push_error("Could not deploy: %s" % error_string(error))


func _update_weapon_description(index: int) -> void:
	match index:
		0:
			weapon_description.text = (
				"Fast, precise fire for fighting across rooms. %d rounds per magazine."
				% CARBINE.magazine_capacity
			)
		1:
			weapon_description.text = (
				"Wide spread for close fights around corners. %d shells per magazine."
				% SHOTGUN.magazine_capacity
			)
		_:
			weapon_description.text = ""

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
