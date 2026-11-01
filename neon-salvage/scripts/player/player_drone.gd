extends CharacterBody2D

const CARBINE_BOLT: PackedScene = preload(
	'res://scenes/projectiles/PrimaryCarbineBolt.tscn'
)

const FIRE_INTERVAL: float = 0.18

@onready var weapon_pivot: Node2D = $VisualRig/WeaponPivot
@onready var muzzle: Marker2D = $VisualRig/WeaponPivot/Muzzle

var fire_timer: float = 0.0

func _process(delta: float) -> void:
	var aim_direction: Vector2 = (
		get_global_mouse_position() - weapon_pivot.global_position
	)
	
	if aim_direction.length_squared() > 4.0:
		weapon_pivot.global_rotation = aim_direction.angle() + PI / 2.0
	
	fire_timer = maxf(fire_timer - delta, 0.0)
	
	if Input.is_action_pressed("fire_primary") and fire_timer <= 0.0:
		fire_primary()
		fire_timer = FIRE_INTERVAL

func fire_primary() -> void:
	var projectile: Area2D = CARBINE_BOLT.instantiate() as Area2D
	
	get_tree().current_scene.add_child(projectile)
	
	projectile.global_position = muzzle.global_position
	projectile.global_rotation = weapon_pivot.global_rotation
