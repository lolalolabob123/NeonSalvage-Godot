class_name DroneGearInventory
extends VBoxContainer

signal loadout_changed

@onready var equipped_summary: Label = $EquippedSummary
@onready var owned_gear_list: ItemList = $OwnedGearList
@onready var item_name: Label = $ItemName
@onready var item_description: Label = $DescriptionScroll/ItemDescription
@onready var equip_button: Button = $EquipButton

var active_slot: StringName = &"weapon"
var entries: Array[Dictionary] = []

func _ready() -> void:
	if ProgressStore.selected_primary_weapon == null:
		var starter_weapon := ProgressStore.get_equipment(&"carbine")
		
		if starter_weapon != null:
			ProgressStore.selected_primary_weapon = (
				starter_weapon.weapon_definition
			)

	owned_gear_list.item_selected.connect(_inspect_item)
	equip_button.pressed.connect(_equip_selected)
	
	ProgressStore.loadout_changed.connect(_on_store_loadout_changed)

	refresh_inventory()

func refresh_inventory(selected_index: int = 0) -> void:
	entries.clear()
	owned_gear_list.clear()
	
	var equipment_slot: EquipmentDefinition.Slot
	
	match active_slot:
		&"weapon":
			equipment_slot = EquipmentDefinition.Slot.PRIMARY_WEAPON
		&"system":
			equipment_slot = EquipmentDefinition.Slot.ACTIVE_SYSTEM
		&"chassis":
			equipment_slot = EquipmentDefinition.Slot.CHASSIS
		_:
			return
	
	var owned_equipment := ProgressStore.get_owned_equipment_for_slot(
		equipment_slot
	)
	
	for equipment in owned_equipment:
		_add_equipment(equipment)
	
	if active_slot == &"system":
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
		
		var item_index := owned_gear_list.add_item(label)
		owned_gear_list.set_item_metadata(
			item_index,
			StringName(entry["id"])
		)
	
	var index := clampi(selected_index, 0, entries.size() - 1)
	owned_gear_list.select(index)
	_inspect_item(index)

func _add_equipment(equipment: EquipmentDefinition) -> void:
	var kind: String
	
	match equipment.slot:
		EquipmentDefinition.Slot.PRIMARY_WEAPON:
			kind = "weapon"
		
		EquipmentDefinition.Slot.ACTIVE_SYSTEM:
			kind = "system"
		
		EquipmentDefinition.Slot.CHASSIS:
			kind = "chassis"
		
		_:
			return
	
	var description := equipment.description
	var weapon := equipment.weapon_definition
	
	if kind == "weapon" and weapon != null:
		description += (
			"\n\nMagazine: %d"
			+ "\nReload: %.1f seconds"
		) % [
			weapon.magazine_capacity,
			weapon.reload_duration,
		]
	
	if kind == "chassis":
		description += (
			"\n\nHull modifier: %+d"
			+ "\nMovement speed: %d%% of standard"
		) % [
			equipment.hull_bonus,
			roundi(equipment.move_speed_multiplier * 100.0),
		]
	
	entries.append({
		"kind": kind,
		"id": equipment.equipment_id,
		"name": equipment.display_name,
		"description": description,
		"weapon": weapon,
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
	var equipment_id := StringName(entry["id"])
	
	var target_slot: EquipmentDefinition.Slot
	match active_slot:
		&"weapon":
			target_slot = EquipmentDefinition.Slot.PRIMARY_WEAPON
		
		&"system":
			target_slot = EquipmentDefinition.Slot.ACTIVE_SYSTEM
		
		&"chassis":
			target_slot = EquipmentDefinition.Slot.CHASSIS
		
		_:
			return
	
	if not ProgressStore.equip_equipment(equipment_id, target_slot):
		equip_button.text = "Cannot equip this item."

func _is_equipped(entry: Dictionary) -> bool:
	match entry["kind"]:
		"weapon":
			return entry["weapon"] == ProgressStore.selected_primary_weapon

		"system":
			return entry["id"] == ProgressStore.selected_system

		"chassis":
			return entry["id"] == ProgressStore.selected_chassis_id

	return false


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
	
	var chassis := ProgressStore.get_equipped_chassis()

	if chassis != null:
		equipped_summary.text += "\nCHASSIS: %s" % chassis.display_name

func select_slot(slot_id: StringName) -> void:
	if slot_id not in [&"weapon", &"system", &"chassis"]:
		return

	active_slot = slot_id
	refresh_inventory()

func _on_store_loadout_changed() -> void:
	var selection := owned_gear_list.get_selected_items()
	var selected_index := 0
	
	if not selection.is_empty():
		selected_index = selection[0]
	
	refresh_inventory(selected_index)
	
	# Notify the schematic through its existing connection.
	loadout_changed.emit()
