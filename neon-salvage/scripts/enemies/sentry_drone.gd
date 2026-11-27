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

enum SentryState {
	GUARD,
	PURSUE,
	INVESTIGATE,
	RETURN_TO_POST
}

@onready var detection_area: Area2D = $DetectionArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = (
	$Sprite2D/BodyTint/GunRig/Muzzle
)

@onready var charge_glow: Sprite2D = (
	$Sprite2D/BodyTint/GunRig/Muzzle/ChargeGlow
)

@onready var charge_audio: AudioStreamPlayer2D = (
	$Sprite2D/BodyTint/GunRig/Muzzle/ChargeAudio
)

@onready var shot_audio: AudioStreamPlayer2D = (
	$Sprite2D/BodyTint/GunRig/Muzzle/ShotAudio
)

@onready var sight_ray: RayCast2D = (
	$Sprite2D/BodyTint/GunRig/Muzzle/SightRay
)
@onready var body_tint: Node2D = $Sprite2D/BodyTint
@onready var gun_rig: Node2D = $Sprite2D/BodyTint/GunRig
@onready var engine_left: Sprite2D = (
	$Sprite2D/BodyTint/EngineLeftSprite
)
@onready var engine_right: Sprite2D = (
	$Sprite2D/BodyTint/EngineRightSprite
)
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

@export var move_speed: float = 115.0
@export var acceleration: float = 450.0
@export var stopping_distance: float = 120.0
@export var rotation_speed: float = 6.0
@export var max_health: int = 4
@export var fire_interval: float = 1.5
@export var windup_duration: float = 0.35
@export var investigation_duration: float = 3.0
@export var guard_scan_angle: float = 30.0
@export var guard_scan_speed: float = 1.0
@export var patrol_route: Node2D = null
@export var aim_lock_duration: float = 0.2
@export var recovery_duration: float = 0.55

var target: Node2D = null
var current_health: int = 0
var fire_timer: float = 0.0
var windup_timer: float = 0.0
var is_winding_up: bool = false
var current_state: SentryState = SentryState.GUARD
var home_position: Vector2 = Vector2.ZERO
var last_known_position: Vector2 = Vector2.ZERO
var has_last_known_position: bool = false
var investigation_timer: float = 0.0
var home_rotation: float = 0.0
var guard_scan_timer: float = 0.0
var patrol_points: Array[Vector2] = []
var patrol_index: int = 0
var emp_stun_remaining: float = 0.0
var aim_locked: bool = false
var shot_duration: bool = false
var shot_direction: Vector2 = Vector2.UP
var recovery_remaining: float = 0.0
var visual_time: float = 0.0
var recoil_tween: Tween
var hit_tween: Tween

func _ready() -> void:
	
	add_to_group("emp_targets")
	home_position = global_position
	home_rotation = rotation
	current_health = max_health
	charge_glow.hide()

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	
	sight_ray.add_exception(self)
	
	# Load waypoints from  the assigned patrol route.
	if patrol_route != null:
		for point in patrol_route.get_children():
			if point is Marker2D:
				patrol_points.append(point.global_position)
				
		if patrol_points.size() >= 2:
			#Set the first patrol destination.
			navigation_agent.target_position = patrol_points[0]


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	if int(body.get("current_health")) <= 0:
		return
	
	# Remember the nearby player.
	# Visibility is checked each physics frame
	target = body

func _on_body_exited(body: Node2D) -> void:
	if body != target:
		return

	target = null

	# Don't restart an investigation already in progress.
	if current_state == SentryState.PURSUE:
		begin_investigation()

func respond_to_alarm(alarm_position: Vector2) -> void:
	if current_health <= 0:
		return
	
	# Keep pursuing a player already in clear view.
	if (
		current_state == SentryState.PURSUE
		and is_instance_valid(target)
		and has_line_of_sight()
	):
		return
	
	# Investigate the reported location.
	last_known_position = alarm_position
	has_last_known_position = true
	begin_investigation()

func begin_investigation() -> void:
	_cancel_attack()

	if has_last_known_position:
		current_state = SentryState.INVESTIGATE
		navigation_agent.target_position = last_known_position
		investigation_timer = investigation_duration
	else:
		current_state = SentryState.RETURN_TO_POST
		navigation_agent.target_position = home_position

func _physics_process(delta: float) -> void:
	
	if current_health <= 0:
		return
	
	if emp_stun_remaining > 0.0:
		emp_stun_remaining = maxf(emp_stun_remaining - delta, 0.0)
		velocity = Vector2.ZERO
		body_tint.modulate = Color("#08DFFF")
		return
	
	var attack_busy := _update_attack(delta)
	_update_attack_visuals()
	
	if attack_busy:
		velocity = Vector2.ZERO
		return
	
	# Update awareness before choosing movement.
	if is_instance_valid(target):
		if int(target.get("current_health")) <= 0:
			target = null
			current_state = SentryState.GUARD
			has_last_known_position = false

			is_winding_up = false
			windup_timer = 0.0
			fire_timer = fire_interval

		elif has_line_of_sight():
			# Only visible positions become remembered positions.
			last_known_position = target.global_position
			has_last_known_position = true

			# Acquire or reacquire the player.
			if current_state != SentryState.PURSUE:
				current_state = SentryState.PURSUE
				navigation_agent.target_position = last_known_position

		elif current_state == SentryState.PURSUE:
			# Sight was lost: investigate the saved position.
			begin_investigation()

	elif current_state == SentryState.PURSUE:
		# Also handle a target that was removed from the scene.
		begin_investigation()
	
	var desired_velocity: Vector2 = Vector2.ZERO

	if current_state == SentryState.PURSUE and is_instance_valid(target):
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
						
	elif current_state == SentryState.INVESTIGATE:
		# Dollow the navigation to the last known position.
		if not navigation_agent.is_navigation_finished():
			var next_point: Vector2 = navigation_agent.get_next_path_position()
			var path_direction: Vector2 = next_point - global_position
			
			if path_direction.length_squared() > 4.0:
				desired_velocity = path_direction.normalized() * move_speed
				
		else:
			# Search briefly after reaching the last known position.
			investigation_timer = maxf(
				investigation_timer - delta,
				0.0
			)	
			
			if investigation_timer <= 0.0:
				current_state = SentryState.RETURN_TO_POST
				navigation_agent.target_position = home_position
	
	elif current_state == SentryState.RETURN_TO_POST:
		# Check whether the Sentry has reached its starting position.
		if navigation_agent.is_navigation_finished():
			current_state = SentryState.GUARD
			has_last_known_position = false
		
		else:
			# Navigate back to the original position.
			var next_point: Vector2 = navigation_agent.get_next_path_position()
			var path_direction: Vector2 = next_point - global_position
			
			if path_direction.length_squared() > 4.0:
				desired_velocity = path_direction.normalized() * move_speed
				
	# Slowly scan the surroundings while guarding
	if current_state == SentryState.GUARD and patrol_points.size() < 2:
		guard_scan_timer += delta
		
		# Sweep left and right around the original facing direction.
		var scan_target: float = (
			home_rotation
			+ deg_to_rad(guard_scan_angle)
			+ sin(guard_scan_timer * guard_scan_speed)
		)
		
		rotation = lerp_angle(
			rotation,
			scan_target,
			minf(rotation_speed * delta, 1.0)
		)
		
	# Patrol between assigned waypoints while guarding.
	if current_state == SentryState.GUARD and patrol_points.size() >= 2:
		var waypoint: Vector2 = patrol_points[patrol_index]
		
		# Move to the next waypoint when close enough.
		if global_position.distance_to(waypoint) <= 35.0:
			patrol_index = (patrol_index + 1) % patrol_points.size()
			waypoint = patrol_points[patrol_index]
		
		# Restore the patrol destination after other AI behaviours.
		if navigation_agent.target_position.distance_to(waypoint) > 1.0:
			navigation_agent.target_position = waypoint
		
		# Follow the navigation path around obstacles.
		if not navigation_agent.is_navigation_finished():
			var next_point: Vector2 = navigation_agent.get_next_path_position()
			var path_direction: Vector2 = next_point - global_position
			
			if path_direction.length_squared() > 4.0:
				desired_velocity = path_direction.normalized() * move_speed
				
				# Face the direction of movement.
				rotation = lerp_angle(
					rotation,
					path_direction.angle() + PI / 2.0,
					minf(rotation_speed * delta, 1.0)
				)
	
	# Accelerate or decelerate smoothly.
	velocity = velocity.move_toward(
		desired_velocity,
		acceleration * delta
	)

	move_and_slide()

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
	if hit_tween != null:
		hit_tween.kill()

	# Briefly brighten the armour without adding a colour tint.
	sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)

	hit_tween = create_tween()
	hit_tween.tween_property(
		sprite,
		"modulate",
		Color.WHITE,
		0.08
	)

func destroy_sentry() -> void:
	
	if hit_tween != null:
		hit_tween.kill()

	sprite.modulate = Color.WHITE
	
	if recoil_tween != null:
		recoil_tween.kill()

	gun_rig.position = Vector2.ZERO
	# Remove any remaining charging visuals.
	charge_glow.hide()
	body_tint.modulate = Color.WHITE

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
	var pulse := SENTRY_PULSE.instantiate() as SentryPulse

	pulse.configure(shot_direction, self)

	var level := get_tree().current_scene as Node2D

	pulse.position = level.to_local(muzzle.global_position)
	level.add_child(pulse)

	shot_audio.play()
	_play_recoil()

func apply_emp(duration: float) -> void:
	if current_health <= 0 or duration <= 0.0:
		return

	_cancel_attack()

	emp_stun_remaining = maxf(
		emp_stun_remaining,
		duration
	)

	velocity = Vector2.ZERO
	body_tint.modulate = Color("#98DFFF")

func _update_attack(delta: float) -> bool:
	fire_timer = maxf(fire_timer - delta, 0.0)
	
	# Remain stationary briefly after firing.
	if recovery_remaining > 0.0:
		recovery_remaining = maxf(
			recovery_remaining - delta,
			0.0
		)
		return true
	
	if is_winding_up:
		if not is_instance_valid(target):
			_cancel_attack()
			return false
		
		if int(target.get("current_health")) <= 0:
			_cancel_attack()
			return false
		
		# Cover can cancel the charge before aim locks.
		if not aim_locked and not has_line_of_sight():
			begin_investigation()
			return false
		
		windup_timer = maxf(windup_timer - delta, 0.0)
		
		if not aim_locked:
			_aim_attack_at_target()

			var lock_window := clampf(
				aim_lock_duration,
				0.0,
				maxf(windup_duration, 0.01)
			)

			if windup_timer <= lock_window:
				aim_locked = true
				shot_direction = Vector2.UP.rotated(
					global_rotation
				)
		
		if windup_timer <= 0.0:
			# Capture a direction even if the lock window is zero.
			if not aim_locked:
				shot_direction = Vector2.UP.rotated(
					global_rotation
				)
			
			is_winding_up = false
			aim_locked = false
			
			fire_at_player()
			
			recovery_remaining = maxf(recovery_duration, 0.0)
			
			fire_timer = maxf(
				fire_interval - maxf(windup_duration, 0.01),
				recovery_remaining
			)
		
		return true
	
	if current_state != SentryState.PURSUE:
		return false
	
	if not is_instance_valid(target):
		return false
	
	if int(target.get("current_health")) <= 0:
		return false
	
	if fire_timer > 0.0 or not has_line_of_sight():
		return false
	
	# Begin a new stationary charge.
	is_winding_up = true
	aim_locked = false
	windup_timer = maxf(windup_duration, 0.01)
	
	_aim_attack_at_target()
	charge_audio.play()
	
	return true

func _aim_attack_at_target() -> void:
	var direction := target.global_position - global_position
	
	if direction.length_squared() > 0.01:
		global_rotation = direction.angle() + PI / 2.0

func _cancel_attack() -> void:
	is_winding_up = false
	aim_locked = false
	windup_timer = 0.0
	recovery_remaining = 0.0
	fire_timer = fire_interval
	
	charge_glow.hide()
	charge_audio.stop()
	body_tint.modulate = Color.WHITE

func _update_attack_visuals() -> void:
	charge_glow.visible = is_winding_up
	
	if is_winding_up:
		var progress := 1.0 - clampf(
			windup_timer / maxf(windup_duration, 0.01),
			0.0,
			1.0
		)
		
		body_tint.modulate = Color.WHITE.lerp(
			Color("#F36A58"),
			progress * 0.25
		)
		
		charge_glow.scale = Vector2.ONE * lerpf(
			0.85,
			1.45,
			progress
		)
		
		# A bright muzzle marks the commited part of the shot.
		if aim_locked:
			charge_glow.modulate = Color("#FFE6A6")
		else:
			charge_glow.modulate = Color.WHITE
	
	else:
		charge_audio.stop()
		charge_glow.modulate = Color.WHITE
		
		if recovery_remaining > 0.0:
			body_tint.modulate = Color("#93A7B3")
		else:
			body_tint.modulate = Color.WHITE

func _process(delta: float) -> void:
	if current_health <= 0:
		return

	visual_time += delta

	# Keep the hover movement vertical on screen as the drone turns.
	var hover_offset := Vector2(
		0.0,
		sin(visual_time * 2.2) * 1.2
	)

	sprite.position = hover_offset.rotated(-global_rotation)

	# Small independent movement in the engine housings.
	var engine_amplitude := 0.35

	if emp_stun_remaining > 0.0:
		engine_amplitude = 0.0

	engine_left.position = Vector2(
		0.0,
		sin(visual_time * 7.0) * engine_amplitude
	)

	engine_right.position = Vector2(
		0.0,
		sin(visual_time * 7.0 + 1.7) * engine_amplitude
	)

func _play_recoil() -> void:
	if recoil_tween != null:
		recoil_tween.kill()

	gun_rig.position = Vector2(0, 3)

	recoil_tween = create_tween()

	recoil_tween.tween_property(
		gun_rig,
		"position",
		Vector2.ZERO,
		0.18
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
