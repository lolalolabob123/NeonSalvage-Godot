extends VBoxContainer

@export var skill_id: StringName
@export_multiline var effect_description: String

@onready var name_label: Label = $NameLabel
@onready var effect_label: Label = $EffectLabel
@onready var purchase_button: Button = $PurchaseButton
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	effect_label.text = effect_description
	purchase_button.pressed.connect(_purchase)
	ProgressStore.banked_salvage_changed.connect(_on_balance_changed)
	_refresh()

func _on_balance_changed(_total: int) -> void:
	_refresh()

func _refresh() -> void:
	status_label.text = ""
	
	var skill: Dictionary = ProgressStore.SKILLS.get(skill_id, {})
	if skill.is_empty():
		name_label.text = "Unknown Skill"
		purchase_button.text = "Unavailable"
		purchase_button.disabled = true
		return
	
	name_label.text = skill["display_name"]
	purchase_button.disabled = not ProgressStore.can_purchase_skill(skill_id)
	
	if ProgressStore.has_skill(skill_id):
		purchase_button.text = "Installed"
		return
	
	var cost := ProgressStore.get_skill_cost(skill_id)
	purchase_button.text = "Install (%d salvage)" % cost
	
	for prerequisite_id in skill["prerequisites"]:
		if not ProgressStore.has_skill(prerequisite_id):
			var prerequisite: Dictionary = ProgressStore.SKILLS[prerequisite_id]
			status_label.text = "Requires %s" % prerequisite["display_name"]
			return
	
	if not ProgressStore.storage_available:
		status_label.text = "Save Unavailable"
	elif ProgressStore.banked_salvage < cost:
		var shortfall := cost - ProgressStore.banked_salvage
		status_label.text = "Need %d more salvage" % shortfall

func _purchase() -> void:
	if not ProgressStore.purchase_skill(skill_id):
		_refresh()
		status_label.text = "Purchase failed. Try again."
