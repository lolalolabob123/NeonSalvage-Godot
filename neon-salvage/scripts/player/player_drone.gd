extends CharacterBody2D

signal salvage_changed(total: int)

signal health_changed(current: int, maximum: int)
signal plyaer_destroyed

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

@onready var current_health: int = max_health

@export var move_speed: float = 240.0
@export var acceleration: float = 1250.0
@export var deceleration: float = 1500.0

@export var max_health: int = 5
@onready var invulnerability_duration: float = 0.75

var fire_timer: float = 0.0
var damage_cooldown: float = 0.0

func _process(delta: float) -> void:
	
	damage_cooldown = maxf(
		damage_cooldown - delta,
		0.0
	)
	
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

func take_damage(amount: int) -> void:
	# Ignore invalid damage, defeated players and repeated hits
	if amount <= 0 or current_health <= 0:
		return
	
	if damage_cooldown > 0.0:
		return
	
	# Apply damage.
	current_health = maxi(current_health - amount, 0)
	
	# Start the invulnerability period.
	damage_cooldown = invulnerability_duration
	
	# Notify the HUD.
	health_changed.emit(current_health, max_health)
	flash_player_hit()
	
	# Handle defeat
	if current_health == 0:
		# player_destroyed.emit()
		
		velocity = Vector2.ZERO
		set_process(false)
		set_physics_process(false)

func flash_player_hit() -> void:
	# Briefly tint the entire drone.
	visual_rig.modulate = Color(1.0, 0.35, 0.35)
	
	# Restore its original colours.
	var tween: Tween = create_tween()
	
	tween.tween_property(
		visual_rig,
		"modulate",
		Color.WHITE,
		0.18
	) 
