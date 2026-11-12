class_name WeaponDefinition
extends Resource

@export var weapon_id: StringName = &"carbine"
@export var display_name: String = "carbine"
@export var projectile_scene: PackedScene
@export var fire_sound: AudioStream

@export_range(0.01, 5.0, 0.01)
var fire_interval: float = 0.18

@export_range(1, 16, 1)
var pellets_per_shot: int = 1

@export_range(0.0, 90.0, 0.5)
var spread_degrees: float = 0.0

@export_range(1, 60, 1) var magazine_capacity: int = 12
@export_range(0.1, 5.0, 0.1) var reload_duration: float = 1.3
