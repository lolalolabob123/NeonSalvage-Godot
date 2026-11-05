extends CharacterBody2D

const DESTRUCTION_FX: PackedScene = preload(
	"res://scenes/effects/SentryDestructionFX.tscn"
)

const SALVAGE_PICKUP: PackedScene = preload(
	"res://scenes/pickups/SalvagePickup.tscn"
)

const SENTRY_PULSE: PackedScene = preload(
	"res://scenes/projectiles/SentryPulse.tscn"
)

@onready var detection_area: Area2D = $DetectionArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var charge_glow: Sprite2D = $Muzzle/ChargeGlow
@onready var sight_ray: RayCast2D = $Muzzle/SightRay
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

@export var move_speed: float = 115.0
@export var acceleration: float = 450.0
@export var stopping_distance: float = 120.0
@export var rotation_speed: float = 6.0
@export var max_health: int = 4
@export var fire_interval: float = 1.5
@export var windup_duration: float = 0.35

var target: Node2D = null
var current_health: int = 0
var fire_timer: float = 0.0
var windup_timer: float = 0.0
var is_winding_up: bool = false


func _ready() -> void:
	current_health = max_health
	charge_glow.hide()

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	
	sight_ray.add_exception(self)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		navigation_agent.target_position = body.global_position


func _on_body_exited(body: Node2D) -> void:
	if body == target:
		target = null


func _physics_process(delta: float) -> void:
	var desired_velocity: Vector2 = Vector2.ZERO

	if is_instance_valid(target):
		var to_player: Vector2 = target.global_position - global_position
		var distance: float = to_player.length()

		if distance > 1.0:
			# Rotate to face the player.
			var target_angle: float = to_player.angle() + PI / 2.0

			rotation = lerp_angle(
				rotation,
				target_angle,
				minf(rotation_speed * delta, 1.0)
			)
			
			# Refresh the route when the player moves.
			if navigation_agent.target_position.distance_to(target.global_position) > 16.0:
				navigation_agent.target_position = target.global_position
			
			# Approach until within firing distance and able to see the player.
			if distance > stopping_distance or not has_line_of_sight():
				if not navigation_agent.is_navigation_finished():
					var next_point: Vector2 = navigation_agent.get_next_path_position()
					var path_direction: Vector2 = next_point - global_position
					
					if path_direction.length_squared() > 4.0:
						desired_velocity = path_direction.normalized() * move_speed
	# Accelerate or decelerate smoothly.
	velocity = velocity.move_toward(
		desired_velocity,
		acceleration * delta
	)

	move_and_slide()

	# Handle automatic firing.
	if is_instance_valid(target) and has_line_of_sight():
		if is_winding_up:
			# Count down the weapon charging phase.
			windup_timer -= delta

			if windup_timer <= 0.0:
				is_winding_up = false

				# Fire after charging finishes.
				fire_at_player()

				# Maintain the intended firing interval.
				fire_timer = maxf(
					fire_interval - windup_duration,
					0.0
				)

		else:
			# Wait until it's time to prepare another shot.
			fire_timer -= delta

			if fire_timer <= 0.0:
				is_winding_up = true
				windup_timer = windup_duration

	else:
		# Cancel charging if the player leaves detection range.
		is_winding_up = false
		windup_timer = 0.0
		fire_timer = fire_interval

	# Update charging visuals every physics frame.
	charge_glow.visible = is_winding_up

	if is_winding_up:
		var charge_progress: float = 1.0 - clampf(
			windup_timer / maxf(windup_duration, 0.01),
			0.0,
			1.0
		)

		# Gradually tint the Sentry red-orange.
		sprite.self_modulate = Color.WHITE.lerp(
			Color("#F36A58"),
			charge_progress
		)

		# Grow the energy buildup at the muzzle.
		var glow_scale: float = lerpf(
			0.45,
			1.2,
			charge_progress
		)

		charge_glow.scale = Vector2.ONE * glow_scale

	else:
		sprite.self_modulate = Color.WHITE

func has_line_of_sight() -> bool:
	if not is_instance_valid(target):
		return false
	
	# Point the ray directly towards the player.
	sight_ray.target_position = sight_ray.to_local(
		target.global_position
	)
	
	# Immediately update the raycast result.
	sight_ray.force_raycast_update()
	
	# Only return true if the first object hit is the player.
	return(
		sight_ray.is_colliding()
		and sight_ray.get_collider() == target
	)

func take_damage(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return

	current_health = maxi(current_health - amount, 0)

	if current_health == 0:
		destroy_sentry()
		return

	flash_hit()


func flash_hit() -> void:
	# Temporarily tint the enemy red.
	sprite.modulate = Color(1.0, 0.35, 0.35)

	# Smoothly restore its original colour.
	var tween: Tween = create_tween()

	tween.tween_property(
		sprite,
		"modulate",
		Color.WHITE,
		0.14
	)


func destroy_sentry() -> void:
	# Remove any remaining charging visuals.
	charge_glow.hide()
	sprite.self_modulate = Color.WHITE

	# Stop enemy movement.
	velocity = Vector2.ZERO
	set_physics_process(false)

	# Disable collisions and detection.
	$CollisionShape2D.set_deferred("disabled", true)
	detection_area.set_deferred("monitoring", false)

	# Create the destruction particles.
	var debris: CPUParticles2D = (
		DESTRUCTION_FX.instantiate() as CPUParticles2D
	)

	# Add them to the level rather than the enemy.
	get_tree().current_scene.add_child(debris)

	# Spawn the debris where the enemy was destroyed.
	debris.global_position = global_position

	# Automatically remove the effect once it finishes.
	debris.finished.connect(debris.queue_free)

	# Start the particle burst.
	debris.emitting = true

	# Animate the destruction.
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# Briefly expand the enemy.
	tween.tween_property(
		sprite,
		"scale",
		Vector2(1.35, 1.35),
		0.18
	)

	# Fade out with a warm red-orange tint.
	tween.tween_property(
		sprite,
		"modulate",
		Color(1.0, 0.45, 0.25, 0.0),
		0.18
	)

	# Spawn salvage when the destruction animation finishes.
	tween.finished.connect(spawn_salvage_drop)

	# Remove the enemy when the animation finishes.
	tween.finished.connect(queue_free)


func spawn_salvage_drop() -> void:
	var pickup: Area2D = SALVAGE_PICKUP.instantiate() as Area2D
	var level: Node2D = get_tree().current_scene as Node2D

	# Position the pickup where the enemy was destroyed.
	pickup.position = level.to_local(global_position)

	# Add the pickup directly to the level.
	level.add_child(pickup)


func fire_at_player() -> void:
	if not is_instance_valid(target):
		return

	# Calculate the direction from the muzzle to the player.
	var direction: Vector2 = (
		target.global_position - muzzle.global_position
	)

	# Create an enemy projectile.
	var pulse: SentryPulse = (
		SENTRY_PULSE.instantiate() as SentryPulse
	)

	# Configure its direction and owner.
	pulse.configure(direction, self)

	# Add the projectile to the level.
	var level: Node2D = get_tree().current_scene as Node2D

	pulse.position = level.to_local(muzzle.global_position)
	level.add_child(pulse)
