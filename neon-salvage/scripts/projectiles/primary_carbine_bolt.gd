extends Area2D

@export var speed: float = 680.0
@export var lifetime: float = 1.2

const IMPACT_EFFECT: PackedScene = preload(
	"res://scenes/effects/CarbineImpact.tscn"
)

var alive_time: float = 0.0

func _physics_process(delta: float) -> void:
	var direction: Vector2 = Vector2.UP.rotated(global_rotation)
	
	global_position += direction * speed * delta
	alive_time += delta
	
	if alive_time >= lifetime:
		queue_free()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1)
		
	var impact: Node2D = IMPACT_EFFECT.instantiate()
	get_tree().current_scene.add_child(impact)
	impact.global_position = global_position
		
	queue_free()
