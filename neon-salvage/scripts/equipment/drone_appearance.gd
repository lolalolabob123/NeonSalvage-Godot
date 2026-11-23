class_name DroneAppearance
extends Node2D

enum ThrusterPart {
	ASSEMBLY,
	LEFT,
	RIGHT,
}

@export var equipment_slot: EquipmentDefinition.Slot = (
	EquipmentDefinition.Slot.CHASSIS
)
@export var follow_loadout_changes: bool = true
@export var weapon_source: Node
@export var thruster_part: ThrusterPart = ThrusterPart.ASSEMBLY

var current_visual: Node2D = null
var displayed_scene: PackedScene = null


func _ready() -> void:
	if follow_loadout_changes:
		ProgressStore.loadout_changed.connect(refresh_appearance)

	refresh_appearance()


func _get_equipment_definition() -> EquipmentDefinition:
	match equipment_slot:
		EquipmentDefinition.Slot.CHASSIS:
			return ProgressStore.get_equipped_chassis()

		EquipmentDefinition.Slot.PRIMARY_WEAPON:
			var weapon: WeaponDefinition = (
				ProgressStore.selected_primary_weapon
			)

			# Supports running a level directly from the editor.
			if weapon == null and is_instance_valid(weapon_source):
				weapon = weapon_source.get(
					"primary_weapon"
				) as WeaponDefinition

			# The menu uses Carbine before a first weapon selection.
			if weapon == null:
				return ProgressStore.get_equipment(&"carbine")

			return ProgressStore.get_equipment_for_weapon(weapon)
		
		EquipmentDefinition.Slot.THRUSTERS:
			return ProgressStore.get_equipped_thrusters()
		
		EquipmentDefinition.Slot.ACTIVE_SYSTEM:
			var system_id := ProgressStore.selected_system
				
			if system_id == &"":
				return null
			
			if not ProgressStore.owns_equipment(system_id):
				return null
			
			return ProgressStore.get_equipment(system_id)

	return null


func refresh_appearance() -> void:
	var equipment := _get_equipment_definition()

	if equipment == null:
		_clear_visual()

		# An empty active system slot is allowed.
		if equipment_slot != EquipmentDefinition.Slot.ACTIVE_SYSTEM:
			push_warning(
				"Equipment missing for slot: %s" % equipment_slot
			)

		return

	if equipment.visual_scene == null:
		_clear_visual()
		push_warning(
			"Equipment visual missing for slot: %s" % equipment_slot
		)
		return

	var requested_scene: PackedScene = equipment.visual_scene

	if requested_scene == displayed_scene:
		return

	var instance := requested_scene.instantiate()

	if not instance is Node2D:
		instance.free()
		push_error("Equipment visual scenes need a Node2D root.")
		return
	
	if (
		equipment_slot == EquipmentDefinition.Slot.THRUSTERS
		and thruster_part != ThrusterPart.ASSEMBLY
	):
		instance = _extract_thruster_part(instance as Node2D)

		if instance == null:
			return

	if is_instance_valid(current_visual):
		remove_child(current_visual)
		current_visual.queue_free()

	current_visual = instance as Node2D
	displayed_scene = requested_scene

	add_child(current_visual)

func _extract_thruster_part(assembly: Node2D) -> Node2D:
	var part_name := "LeftThruster"

	if thruster_part == ThrusterPart.RIGHT:
		part_name = "RightThruster"

	var part := assembly.get_node_or_null(part_name) as Node2D

	if part == null:
		assembly.free()
		push_error("Thruster visual is missing: %s" % part_name)
		return null

	assembly.remove_child(part)
	assembly.free()

	# Gameplay already supplies the left/right mount position.
	part.position = Vector2.ZERO
	return part

func _clear_visual() -> void:
	if is_instance_valid(current_visual):
		remove_child(current_visual)
		current_visual.queue_free()
	
	current_visual = null
	displayed_scene = null
