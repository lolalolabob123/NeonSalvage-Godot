extends CharacterBody2D

signal salvage_changed(total: int)

var salvage_total: int = 0

const CARBINE_BOLT: PackedScene = preload(
	'res://scenes/projectiles/PrimaryCarbineBolt.tscn'
)

const FIRE_INTERVAL: float = 0.18

@onready var weapon_pivot: Node2D = $VisualRig/WeaponPivot
@onready var muzzle: Marker2D = $VisualRig/WeaponPivot/Muzzle
@onready var visual_rig: Node2D = $VisualRig
@onready var left_thruster_pivot: Node2D = $VisualRig/ThrusterLeftPivot
@onready var right_thruster_pivot: Node2D = $VisualRig/ThrusterRightPivot

@export var move_speed: float = 240.0
@export var acceleration: float = 1250.0
@export var deceleration: float = 1500.0

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

func _physics_process(delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	
	var target_velocity: Vector2 = input_direction * move_speed
	
	var change_rate: float = (
		acceleration
		if input_direction != Vector2.ZERO
		else deceleration
	)
	
	velocity = velocity.move_toward(
		target_velocity,
		change_rate * delta
	)
	
	move_and_slide()
	
	update_flight_bank(delta)

func update_flight_bank(delta: float) -> void:
	var strafe: float = clampf(
		velocity.x / move_speed,
		-1.0,
		1.0
	)
	
	var blend: float = minf(delta * 8.0, 1.0)
	
	#Lean the hull towards horizontal movement.
	var hull_angle: float = deg_to_rad(5.0 * strafe)
	
	# Angle the thrusters against horizontal movement.
	var thruster_angle: float = deg_to_rad(-9.0 * strafe)
	
	visual_rig.rotation = lerp_angle(
		visual_rig.rotation,
		hull_angle,
		blend
	)
	
	left_thruster_pivot.rotation = lerp_angle(
		left_thruster_pivot.rotation,
		thruster_angle,
		blend
	)
	
	right_thruster_pivot.rotation = lerp_angle(
		right_thruster_pivot.rotation,
		thruster_angle,
		blend
	)
	
func add_salvage(amount: int) -> void:
	if amount <= 0:
		return
		
	salvage_total += amount
	salvage_changed.emit(salvage_total)
		
	print("Total salvage: ", salvage_total)
