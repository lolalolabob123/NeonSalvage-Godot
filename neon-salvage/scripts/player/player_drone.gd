extends CharacterBody2D

signal salvage_changed(total: int)

signal health_changed(current: int, maximum: int)
signal player_destroyed

var salvage_total: int = 0

const CARBINE_BOLT: PackedScene = preload(
	'res://scenes/projectiles/PrimaryCarbineBolt.tscn'
)

const PLAYER_DESTRUCTION_FX: PackedScene = preload("res://scenes/effects/PlayerDestructionFX.tscn")

const FIRE_INTERVAL: float = 0.18

@onready var weapon_pivot: Node2D = $VisualRig/WeaponPivot
@onready var muzzle: Marker2D = $VisualRig/WeaponPivot/Muzzle
@onready var visual_rig: Node2D = $VisualRig
@onready var left_thruster_pivot: Node2D = $VisualRig/ThrusterLeftPivot
@onready var right_thruster_pivot: Node2D = $VisualRig/ThrusterRightPivot
@onready var invulnerability_duration: float = 0.75
@onready var current_health: int = max_health
@onready var dash_trail: CPUParticles2D = $DashTrail

@export_group("Thruster Dash")

@export var move_speed: float = 240.0
@export var acceleration: float = 1250.0
@export var deceleration: float = 1500.0
@export var max_health: int = 5
@export var dash_unlocked: bool = false
@export var dash_speed: float = 950.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 2.0

var fire_timer: float = 0.0
var damage_cooldown: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_time_remaining: float = 0.0
var dash_cooldown_remaining: float = 0.0

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
	
	# Update the dash timers.
	var was_dashing: bool = dash_time_remaining > 0.0
	
	dash_time_remaining = maxf(
		dash_time_remaining - delta,
		0.0
	)
	
	dash_cooldown_remaining = maxf(
		dash_cooldown_remaining - delta,
		0.0
	)
	
	# Start a dash if unlocked and available.
	if (
		dash_unlocked
		and dash_cooldown_remaining <= 0.0
		and Input.is_action_just_pressed("dash")
	):
		var requested_direction: Vector2 = input_direction
		
		# When stationary, dash towards the mouse.
		if requested_direction == Vector2.ZERO:
			requested_direction = (
				get_global_mouse_position() - global_position
			)
		
		if requested_direction.length_squared() > 0.01:
			dash_direction = requested_direction.normalized()
			dash_time_remaining = dash_duration
			dash_cooldown_remaining = dash_cooldown
			dash_trail.global_rotation = dash_direction.angle()
			dash_trail.emitting = true
	
	# Apply dash movement
	if dash_time_remaining > 0.0:
		velocity = dash_direction * dash_speed
	
	else:
		# Return to normal speed after a dash.
		if was_dashing:
			dash_trail.emitting = false
			velocity = input_direction * move_speed
		
		var target_velocity: Vector2 = (
			input_direction * move_speed
		)
		
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
	# Ignore invalid damage and defeated players
	if amount <= 0 or current_health <= 0:
		return
		
	# Ignore damage while performing a Thruster Dash.
	if dash_time_remaining > 0.0:
		return
	
	# Ignore damage during the normal invulnerability period.
	if damage_cooldown > 0.0:
		return
	
	# Apply damage.
	current_health = maxi(current_health - amount, 0)
	
	# Start the invulnerability period.
	damage_cooldown = invulnerability_duration
	
	# Notify the HUD.
	health_changed.emit(current_health, max_health)
	
	# Handle defeat.
	if current_health == 0:
		velocity = Vector2.ZERO
		set_process(false)
		set_physics_process(false)
		
		# Create the destruction particles.
		var destruction_fx: CPUParticles2D = (
			PLAYER_DESTRUCTION_FX.instantiate() as CPUParticles2D
		)
		
		# Add the effect to the level.
		get_tree().current_scene.add_child(destruction_fx)
		
		# Position the explosion at the player's location.
		destruction_fx.global_position = global_position
		
		# Remove the particles automatically when finished.
		destruction_fx.finished.connect(destruction_fx.queue_free)
		
		# Start the explosion.
		destruction_fx.emitting = true
		
		# Create the destruction animation.
		var destruction_tween: Tween = create_tween()
		destruction_tween.set_parallel(true)
		
		# Shrink the drone.
		destruction_tween.tween_property(
			visual_rig,
			"scale",
			Vector2(0.1, 0.1),
			0.35
		)
		
		# Fade the drone with cyan tint.
		destruction_tween.tween_property(
			visual_rig,
			"modulate",
			Color(0.3, 1.0, 1.0, 0.0),
			0.35
		)
		
		# Wait for the drone's destruction animation.
		await destruction_tween.finished
		
		# Give the remaining particles time to disappear.
		await get_tree().create_timer(0.25).timeout
		
		# Display the game over screen.
		player_destroyed.emit()
		return
		
	# Only flash if the player survived the hit.
	flash_player_hit()

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
