class_name WeaponDefinition
extends Resource

@export var weapon_id: StringName = &"carbine"
@export var display_name: String = "carbine"
@export var projectile_scene: PackedScene

@export_range(0.01, 5.0, 0.01)
var fire_interval: float = 0.18
