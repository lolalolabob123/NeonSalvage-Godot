class_name EquipmentDefinition
extends Resource

enum Slot {
	CHASIS,
	PRIMARY_WEAPON,
	SECONDARY_WEAPON,
	THRUSTERS,
	ACTIVE_SYSTEM,
	UTILITY,
}

@export_group("Identity")
@export var equipment_id: StringName
@export var display_name: String
@export_multiline var description: String
@export var slot: Slot = Slot.PRIMARY_WEAPON
@export var icon: Texture2D

@export_group("Weapon")
@export var weapon_definition: WeaponDefinition

@export_group("Passive Modifiers")
@export var hull_bonus: int = 0
@export_range(0.1, 3.0, 0.05) var move_speed_multiplier: float = 1.0

@export_group("Appearance")
@export var visual_scene: PackedScene
