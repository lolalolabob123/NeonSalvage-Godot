extends Control

@export var mission_scene: PackedScene

@onready var banked_label: Label = $Center/Panel/Margin/Content/BankedLabel
@onready var deploy_button: Button = $Center/Panel/Margin/Content/DeployButton
@onready var hull_upgrade_button: Button = $Center/Panel/Margin/Content/HullUpgradeButton
@onready var upgrade_status: Label = $Center/Panel/Margin/Content/UpgradeStatus

func _ready() -> void:
	_update_bank_balance(ProgressStore.banked_salvage)
	
	ProgressStore.banked_salvage_changed.connect(
		_update_bank_balance
	)
	deploy_button.pressed.connect(_deploy)
	
	hull_upgrade_button.pressed.connect(_purchase_hull_upgrade)

func _update_bank_balance(total: int) -> void:
	banked_label.text = "Banked salvage: %d" % total
	_update_hull_upgrade_button()

func _deploy() -> void:
	if mission_scene == null:
		push_error("PreperationScene needs its Mission Scene assigned.")
		return
	
	deploy_button.disabled = true
	get_tree().paused = false
	
	var error := get_tree().change_scene_to_packed(mission_scene)
	
	if error != OK:
		deploy_button.disabled = false
		push_error("Could not deploy: %s" % error_string(error))

func _update_hull_upgrade_button() -> void:
	if ProgressStore.hull_reinforced:
		hull_upgrade_button.text = "Hull Reinforcement installed"
		hull_upgrade_button.disabled = true
		upgrade_status.text = "+1 maximum hull on every deployment."
	else:
		hull_upgrade_button.text = "Hull Reinforcement — 10 salvage"
		hull_upgrade_button.disabled = (
			not ProgressStore.storage_available
			or ProgressStore.banked_salvage
			< ProgressStore.HULL_REINFORCEMENT_COST
		)
		upgrade_status.text = "Permanent upgrade: +1 maximum hull."


func _purchase_hull_upgrade() -> void:
	if ProgressStore.purchase_hull_reinforcement():
		_update_hull_upgrade_button()
	else:
		upgrade_status.text = "Purchase could not be completed."
