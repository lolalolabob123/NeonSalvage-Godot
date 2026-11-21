class_name DroneGearInventory
extends VBoxContainer

signal loadout_changed

const CARBINE: WeaponDefinition = preload(
	"res://resources/weapons/Carbine.tres"
)
const SHOTGUN: WeaponDefinition = preload(
	"res://resources/weapons/Shotgun.tres"
)

@onready var equipped_summary: Label = $EquippedSummary
@onready var owned_gear_list: ItemList = $OwnedGearList
@onready var item_name: Label = $ItemName
@onready var item_description: Label = $ItemDescription
@onready var equip_button: Button = $EquipButton

var active_slot: StringName = &"weapon"
var entries: Array[Dictionary] = []

func _ready() -> void:
	if ProgressStore.selected_primary_weapon == null:
		ProgressStore.selected_primary_weapon = CARBINE

	owned_gear_list.item_selected.connect(_inspect_item)
	equip_button.pressed.connect(_equip_selected)

	refresh_inventory()


func refresh_inventory(selected_index: int = 0) -> void:
	entries.clear()
	owned_gear_list.clear()
	
	if active_slot == &"weapon:":
		_add_weapon(
			CARBINE,
			"Precise fire for fighting across rooms."
		)
		_add_weapon(
			SHOTGUN,
			"Wide spread for close fights around corners."
		)
	
	elif active_slot == &"system":
		for gear_id in ProgressStore.GEAR:
			if not ProgressStore.owns_gear(gear_id):
				continue
			var gear: Dictionary = ProgressStore.GEAR[gear_id]
			
			entries.append({
				"kind": "system",
				"id": gear_id,
				"name": gear["display_name"],
				"description": _get_system_description(gear_id)
			})
		
		entries.append({
			"kind": "system",
			"id": &"",
			"name": "Empty active system slot",
			"description": "Deploy without an active system.",
		})
	
	_update_equipped_summary()
	
	if entries.is_empty():
		item_name.text = "No compatible equipment"
		item_description.text = ""
		equip_button.text = "Unavailable"
		equip_button.disabled = true
		return
	
	for entry in entries:
		var label: String = entry["name"]
		
		if _is_equipped(entry):
			label += "  [Equipped]"
		
		owned_gear_list.add_item(label)
	
	var index := clampi(selected_index, 0, entries.size() - 1)
	owned_gear_list.select(index)
	_inspect_item(index)


func _add_weapon(
	weapon: WeaponDefinition,
	description: String
) -> void:
	entries.append({
		"kind": "weapon",
		"weapon": weapon,
		"name": weapon.display_name,
		"description": (
			description
			+ "\n\nMagazine: %d"
			+ "\nReload: %.1f seconds"
		) % [
			weapon.magazine_capacity,
			weapon.reload_duration,
		],
	})


func _inspect_item(index: int) -> void:
	if index < 0 or index >= entries.size():
		return

	var entry: Dictionary = entries[index]

	item_name.text = entry["name"]
	item_description.text = entry["description"]

	var equipped := _is_equipped(entry)
	equip_button.disabled = equipped

	if equipped:
		equip_button.text = "Equipped"
	elif entry["kind"] == "system" and entry["id"] == &"":
		equip_button.text = "Unequip active system"
	else:
		equip_button.text = "Equip"


func _equip_selected() -> void:
	var selection := owned_gear_list.get_selected_items()

	if selection.is_empty():
		return

	var index: int = selection[0]
	var entry: Dictionary = entries[index]

	if entry["kind"] == "weapon":
		ProgressStore.selected_primary_weapon = (
			entry["weapon"] as WeaponDefinition
		)
	else:
		var gear_id := StringName(entry["id"])

		if gear_id != &"" and not ProgressStore.owns_gear(gear_id):
			return

		ProgressStore.selected_system = gear_id

	refresh_inventory(index)
	loadout_changed.emit()


func _is_equipped(entry: Dictionary) -> bool:
	if entry["kind"] == "weapon":
		return entry["weapon"] == ProgressStore.selected_primary_weapon

	return entry["id"] == ProgressStore.selected_system


func _update_equipped_summary() -> void:
	var weapon := ProgressStore.selected_primary_weapon
	var weapon_name := "None"

	if weapon != null:
		weapon_name = weapon.display_name

	var system_name := "None"
	var system_id := ProgressStore.selected_system

	if ProgressStore.owns_gear(system_id):
		var gear: Dictionary = ProgressStore.GEAR[system_id]
		system_name = gear["display_name"]

	equipped_summary.text = (
		"PRIMARY WEAPON: %s\nACTIVE SYSTEM: %s"
	) % [weapon_name, system_name]


func _get_system_description(gear_id: StringName) -> String:
	match gear_id:
		ProgressStore.SHIELD_GENERATOR_ID:
			return (
				"Blocks hull damage for 1.5 seconds.\n\n"
				+ "Activation: Q\n"
				+ "Cooldown: 8 seconds after the shield expires."
			)

		ProgressStore.EMP_EMITTER_ID:
			return (
				"Interrupts and stuns nearby enemies without dealing damage.\n\n"
				+ "Activation: Q\n"
				+ "Radius: 220 pixels\n"
				+ "Stun: 2 seconds\n"
				+ "Cooldown: 10 seconds"
			)

		_:
			return "Active system."

func select_slot(slot_id: StringName) -> void:
	if slot_id != &"weapon" and slot_id != &"system":
		return
	
	active_slot = slot_id
	refresh_inventory()
