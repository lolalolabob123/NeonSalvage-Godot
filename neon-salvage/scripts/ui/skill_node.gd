extends VBoxContainer

@export var skill_id: StringName
@export_multiline var effect_description: String

@onready var name_label: Label = $NameLabel
@onready var effect_label: Label = $EffectLabel
@onready var purchase_button: Button = $PurchaseButton

func _ready() -> void:
	effect_label.text = effect_description
	purchase_button.pressed.connect(_purchase)
	ProgressStore.banked_salvage_changed.connect(_on_balance_changed)
	_refresh()

func _on_balance_changed(_total: int) -> void:
	_refresh()

func _refresh() -> void:
	var skill: Dictionary = ProgressStore.SKILLS.get(skill_id, {})
	if skill.is_empty():
		name_label.text = "Unknown skill"
		purchase_button.disabled = true
		return

	name_label.text = skill["display_name"]
	purchase_button.disabled = not ProgressStore.can_purchase_skill(skill_id)

	if ProgressStore.has_skill(skill_id):
		purchase_button.text = "Installed"
		return

	for prerequisite_id in skill["prerequisites"]:
		if not ProgressStore.has_skill(prerequisite_id):
			var prerequisite: Dictionary = ProgressStore.SKILLS[prerequisite_id]
			purchase_button.text = "Requires %s" % prerequisite["display_name"]
			return

	purchase_button.text = "%d salvage" % ProgressStore.get_skill_cost(skill_id)

func _purchase() -> void:
	if not ProgressStore.purchase_skill(skill_id):
		_refresh()
		purchase_button.text = "Purchase failed. Try again."
