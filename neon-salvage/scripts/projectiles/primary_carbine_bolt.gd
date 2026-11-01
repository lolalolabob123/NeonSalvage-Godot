extends Area2D

@export var speed: float = 680.0
@export var lifetime: float = 1.2

var alive_time: float = 0.0

func _physics_process(delta: float) -> void:
	var direction: Vector2 = Vector2.UP.rotated(global_rotation)
	
	global_position += direction * speed * delta
	alive_time += delta
	
	if alive_time >= lifetime:
		queue_free()
