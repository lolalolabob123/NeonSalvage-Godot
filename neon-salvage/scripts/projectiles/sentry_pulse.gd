
class_name SentryPulse
extends Area2D

@export var speed: float = 330.0
@export var lifetime: float = 2.0

var travel_direction: Vector2 = Vector2.UP
var shooter: Node2D = null
var alive_time: float = 0.0
var has_hit: bool = false

func configure(direction: Vector2, source: Node2D) -> void:
	travel_direction = direction.normalized()
	shooter = source

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# Move to the direction provided by the enemy.
	global_position += travel_direction * speed * delta
	
	# Track the projectile's lifetime
	alive_time += delta
	
	if alive_time >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Ignore the enemy that fired the projectile.
	if body == shooter:
		return
	
	# Prevent multiple hits.
	if has_hit:
		return
	
	has_hit = true
	
	if body.is_in_group("player"):
		# Damage the player.
		if body.has_method("take_damage"):
			body.take_damage(1)
	
	queue_free()
