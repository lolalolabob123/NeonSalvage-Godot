extends CharacterBody2D

const SALVAGE_PICKUP: PackedScene = preload(
	"res://scenes/pickups/SalvagePickup.tscn"
)

enum State {
	CHASE,
	WINDUP,
	LUNGE,
	RECOVER,
}

@export var max_health: int = 3
@export var detection_range: float = 420.0
@export var chase_speed: float = 160.0
@export var lunge_trigger_distance: float = 180.0
@export var windup_duration: float = 0.7
@export var lunge_speed: float = 600.0
@export var lunge_duration: float = 0.4
@export var recovery_duration: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var engine_left: Sprite2D = $Sprite2D/EngineLeftSprite
@onready var engine_right: Sprite2D = $Sprite2D/EngineRightSprite
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sight_ray: RayCast2D = $SightRay

var current_health: int = 0
var current_state: State = State.CHASE
var state_time: float = 0.0
var alerted: bool = false
var lunge_direction: Vector2 = Vector2.UP
var emp_stun_remaining: float = 0.0
var visual_time: float = 0.0


func _ready() -> void:
	add_to_group("emp_targets")
	current_health = max_health
	sight_ray.add_exception(self)


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return
	
	if emp_stun_remaining > 0.0:
		emp_stun_remaining = maxf(emp_stun_remaining - delta, 0.0)
		velocity = Vector2.ZERO
		sprite.modulate = Color("#98DFFF")
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D

	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return

	if int(player.get("current_health")) <= 0:
		velocity = Vector2.ZERO
		current_state = State.CHASE
		alerted = false
		queue_redraw()
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()

	match current_state:
		State.CHASE:
			sprite.modulate = Color.WHITE
			velocity = Vector2.ZERO

			if not alerted:
				if distance <= detection_range and _can_see(player):
					alerted = true
					navigation_agent.target_position = player.global_position
				else:
					queue_redraw()
					return

			if distance > detection_range * 1.6:
				alerted = false
				queue_redraw()
				return

			if distance <= lunge_trigger_distance and _can_see(player):
				lunge_direction = to_player.normalized()

				if lunge_direction == Vector2.ZERO:
					lunge_direction = Vector2.UP

				global_rotation = lunge_direction.angle() + PI * 0.5
				current_state = State.WINDUP
				state_time = maxf(windup_duration, 0.1)
			else:
				_chase(player)
				move_and_slide()

		State.WINDUP:
			velocity = Vector2.ZERO
			sprite.modulate = Color.WHITE.lerp(Color("#FFE39A"), 0.25)
			state_time = maxf(state_time - delta, 0.0)

			if state_time <= 0.0:
				current_state = State.LUNGE
				state_time = maxf(lunge_duration, 0.1)

		State.LUNGE:
			sprite.modulate = Color.WHITE.lerp(Color("#FF665C"), 0.25)
			velocity = lunge_direction * lunge_speed

			var step_time := minf(delta, state_time)
			var collision := move_and_collide(velocity * step_time)

			state_time = maxf(state_time - delta, 0.0)

			if collision != null:
				var body := collision.get_collider()

				if body is Node:
					if body.is_in_group("player"):
						body.call("take_damage", 1)

				_begin_recovery()
			elif state_time <= 0.0:
				_begin_recovery()

		State.RECOVER:
			velocity = Vector2.ZERO
			sprite.modulate = Color("#82939C")
			state_time = maxf(state_time - delta, 0.0)

			if state_time <= 0.0:
				current_state = State.CHASE

	queue_redraw()


func _chase(player: Node2D) -> void:
	if NavigationServer2D.map_get_iteration_id(
		navigation_agent.get_navigation_map()
	) == 0:
		return

	if navigation_agent.target_position.distance_to(
		player.global_position
	) > 24.0:
		navigation_agent.target_position = player.global_position

	if navigation_agent.is_navigation_finished():
		return

	var next_position := navigation_agent.get_next_path_position()
	var direction := next_position - global_position

	if direction.length_squared() > 4.0:
		velocity = direction.normalized() * chase_speed
		global_rotation = direction.angle() + PI * 0.5


func _can_see(player: Node2D) -> bool:
	sight_ray.target_position = sight_ray.to_local(
		player.global_position
	)
	sight_ray.force_raycast_update()

	return (
		sight_ray.is_colliding()
		and sight_ray.get_collider() == player
	)


func _begin_recovery() -> void:
	velocity = Vector2.ZERO
	current_state = State.RECOVER
	state_time = maxf(recovery_duration, 0.1)


func take_damage(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return
	
	current_health = maxi(current_health - amount, 0)
	
	if current_health <= 0:
		velocity = Vector2.ZERO
		set_physics_process(false)
		call_deferred("_finish_death")

func _draw() -> void:
	if current_health <= 0 or emp_stun_remaining > 0.0:
		return

	match current_state:
		State.WINDUP:
			_draw_charge_warning()

		State.LUNGE:
			_draw_lunge_streaks()

		State.RECOVER:
			_draw_recovery_ring()

func _finish_death() -> void:
	var level := get_tree().current_scene as Node2D
	
	if not is_instance_valid(level):
		queue_free()
		return	
	
	var pickup := SALVAGE_PICKUP.instantiate() as Area2D
	pickup.position = level.to_local(global_position)
	level.add_child(pickup)
	
	queue_free()

func apply_emp(duration: float) -> void:
	if current_health <= 0 or duration <= 0.0:
		return

	emp_stun_remaining = maxf(emp_stun_remaining, duration)

	velocity = Vector2.ZERO
	current_state = State.CHASE
	state_time = 0.0
	alerted = true

	sprite.modulate = Color("#98DFFF")
	queue_redraw()

func _draw_charge_warning() -> void:
	var progress := 1.0 - clampf(
		state_time / maxf(windup_duration, 0.1),
		0.0,
		1.0
	)

	var reach := maxf(
		lunge_speed * maxf(lunge_duration, 0.1),
		40.0
	)

	var warning_color := Color("#F3AC57").lerp(
		Color("#FFE6A6"),
		progress
	)

	var pulse := 0.65 + 0.35 * (
		0.5 + 0.5 * sin(progress * TAU * 2.0)
	)

	var arrow_color := warning_color
	arrow_color.a = pulse

	# Background track around the drone.
	draw_arc(
		Vector2.ZERO,
		34.0,
		0.0,
		TAU,
		64,
		Color(0.95, 0.67, 0.34, 0.18),
		2.0,
		true
	)

	# Fill the ring as the attack approaches.
	if progress > 0.0:
		draw_arc(
			Vector2.ZERO,
			34.0,
			-PI * 0.5,
			-PI * 0.5 + TAU * progress,
			64,
			warning_color,
			3.0,
			true
		)

	# The drone already faces its committed lunge direction.
	draw_line(
		Vector2(0, -30),
		Vector2(0, -reach + 18),
		arrow_color,
		lerpf(2.0, 4.0, progress),
		true
	)

	# Solid arrowhead remains readable during the pulse.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0, -reach),
			Vector2(-10, -reach + 18),
			Vector2(10, -reach + 18),
		]),
		warning_color
	)


func _draw_lunge_streaks() -> void:
	var streak_color := Color(1.0, 0.4, 0.36, 0.65)

	# Positive local Y points behind the lunging drone.
	draw_line(
		Vector2(-14, 22),
		Vector2(-14, 62),
		streak_color,
		3.0,
		true
	)

	draw_line(
		Vector2(14, 22),
		Vector2(14, 62),
		streak_color,
		3.0,
		true
	)

	draw_line(
		Vector2(0, 28),
		Vector2(0, 78),
		Color(1.0, 0.65, 0.45, 0.35),
		2.0,
		true
	)


func _draw_recovery_ring() -> void:
	var remaining_fraction := clampf(
		state_time / maxf(recovery_duration, 0.1),
		0.0,
		1.0
	)

	if remaining_fraction <= 0.0:
		return

	draw_arc(
		Vector2.ZERO,
		34.0,
		-PI * 0.5,
		-PI * 0.5 + TAU * remaining_fraction,
		64,
		Color("#93A7B3"),
		2.0,
		true
	)

func _process(delta: float) -> void:
	if current_health <= 0:
		return

	if emp_stun_remaining > 0.0:
		sprite.position = Vector2.ZERO
		engine_left.position = Vector2.ZERO
		engine_right.position = Vector2.ZERO
		return

	visual_time += delta

	var hover_amount: float = 1.0
	var engine_shift: float = 0.0
	var vibration: float = 0.25

	match current_state:
		State.WINDUP:
			var progress := 1.0 - clampf(
				state_time / maxf(windup_duration, 0.1),
				0.0,
				1.0
			)
			hover_amount = 0.4
			engine_shift = lerpf(0.0, -2.0, progress)
			vibration = lerpf(0.25, 0.55, progress)

		State.LUNGE:
			hover_amount = 0.15
			engine_shift = 2.0
			vibration = 0.4

		State.RECOVER:
			hover_amount = 0.6
			engine_shift = 0.8
			vibration = 0.15

	# Keep the hover vertical on screen as the drone turns.
	var hover := sin(visual_time * 2.8) * hover_amount
	sprite.position = Vector2(0.0, hover).rotated(-global_rotation)

	var left_target := Vector2(
		0.0,
		engine_shift + sin(visual_time * 10.0) * vibration
	)
	var right_target := Vector2(
		0.0,
		engine_shift + sin(visual_time * 10.0 + 1.7) * vibration
	)

	var blend := 1.0 - exp(-18.0 * delta)
	engine_left.position = engine_left.position.lerp(left_target, blend)
	engine_right.position = engine_right.position.lerp(right_target, blend)
