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
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sight_ray: RayCast2D = $SightRay

var current_health: int = 0
var current_state: State = State.CHASE
var state_time: float = 0.0
var alerted: bool = false
var lunge_direction: Vector2 = Vector2.UP


func _ready() -> void:
	current_health = max_health
	sight_ray.add_exception(self)


func _physics_process(delta: float) -> void:
	if current_health <= 0:
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
			sprite.modulate = Color("#FFB45C")
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
			sprite.modulate = Color("#FFE39A")
			state_time = maxf(state_time - delta, 0.0)

			if state_time <= 0.0:
				current_state = State.LUNGE
				state_time = maxf(lunge_duration, 0.1)

		State.LUNGE:
			sprite.modulate = Color("#FF665C")
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
		var pickup := SALVAGE_PICKUP.instantiate() as Area2D
		var level := get_tree().current_scene

		level.add_child(pickup)
		pickup.global_position = global_position
		queue_free()


func _draw() -> void:
	if current_state != State.WINDUP:
		return

	var reach := lunge_speed * lunge_duration
	var warning_color := Color("#FFD166")

	draw_line(
		Vector2(0, -30),
		Vector2(0, -reach),
		warning_color,
		4.0,
		true
	)

	draw_line(
		Vector2(-12, -reach + 18),
		Vector2(0, -reach),
		warning_color,
		3.0,
		true
	)

	draw_line(
		Vector2(12, -reach + 18),
		Vector2(0, -reach),
		warning_color,
		3.0,
		true
	)
