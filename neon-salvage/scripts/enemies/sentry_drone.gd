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

@export var move_speed: float = 115.0
@export var acceleration: float = 450.0
@export var stopping_distance: float = 120.0
@export var rotation_speed: float = 6.0
@export var max_health: int = 4
@export var fire_interval: float = 1.5

var target: Node2D = null
var current_health: int = 0
var fire_timer: float = 0.0

func _ready() -> void:
	current_health = max_health
	
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body

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
			
			# Approach until within firing distance.
			if distance > stopping_distance:
				desired_velocity = to_player.normalized() * move_speed
	# Accelerate or decelerate smoothly.
	velocity = velocity.move_toward(
		desired_velocity,
		acceleration * delta
	)
	
	move_and_slide()
	
	# Handle automatic firing.
	if is_instance_valid(target):
		fire_timer -= delta
		
		if fire_timer <= 0.0:
			fire_at_player()
			fire_timer = fire_interval
	else:
		# Reset the cooldown when the player leaves detection range.
		fire_timer = fire_interval

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
	
	# Animate the destruction
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
	
	# Add the projectile to the Level.
	var level: Node2D = get_tree().current_scene as Node2D
	
	pulse.position = level.to_local(muzzle.global_position)
	level.add_child(pulse)
