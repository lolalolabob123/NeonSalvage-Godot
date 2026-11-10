extends Control

const CARBINE: WeaponDefinition = preload("res://resources/weapons/Carbine.tres")
const SHOTGUN: WeaponDefinition = preload("res://resources/weapons/Shotgun.tres")

@export var mission_scene: PackedScene

@onready var banked_label: Label = $Center/Panel/Margin/Content/BankedLabel
@onready var deploy_button: Button = $Center/Panel/Margin/Content/DeployButton
@onready var hull_upgrade_button: Button = $Center/Panel/Margin/Content/SkillTree/HullUpgradeButton
@onready var upgrade_status: Label = $Center/Panel/Margin/Content/SkillTree/UpgradeStatus
@onready var primary_weapon_selector: OptionButton = $Center/Panel/Margin/Content/PrimaryWeaponSelector
@onready var weapon_description: Label = $Center/Panel/Margin/Content/WeaponDescription

func _ready() -> void:
	_update_bank_balance(ProgressStore.banked_salvage)
	
	ProgressStore.banked_salvage_changed.connect(
		_update_bank_balance
	)
	
	deploy_button.pressed.connect(_deploy)
	hull_upgrade_button.pressed.connect(_purchase_hull_upgrade)
	
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
	_update_hull_upgrade_button()

func _deploy() -> void:
	if mission_scene == null:
		push_error("PreperationScene needs its Mission Scene assigned.")
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

func _update_hull_upgrade_button() -> void:
	var skill_id := ProgressStore.HULL_REINFORCEMENT_ID

	if ProgressStore.has_skill(skill_id):
		hull_upgrade_button.text = "Hull Reinforcement installed"
		hull_upgrade_button.disabled = true
		upgrade_status.text = "+1 maximum hull on every deployment."
	else:
		hull_upgrade_button.text = "Hull Reinforcement — %d salvage" % (
			ProgressStore.get_skill_cost(skill_id)
		)
		hull_upgrade_button.disabled = not ProgressStore.can_purchase_skill(skill_id)
		upgrade_status.text = "Permanent upgrade: +1 maximum hull."

func _purchase_hull_upgrade() -> void:
	if ProgressStore.purchase_skill(ProgressStore.HULL_REINFORCEMENT_ID):
		_update_hull_upgrade_button()
	else:
		upgrade_status.text = "Purchase could not be completed."

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
