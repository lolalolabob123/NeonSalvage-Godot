extends StaticBody2D

const SALVAGE_PICKUP_SCENE: PackedScene = preload("res://scenes/pickups/SalvagePickup.tscn")

@export var max_health: int = 4

@onready var crate_visual: Sprite2D = $CrateVisual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var health: int
var hit_tween: Tween

func _ready() -> void:
	health = max_health
	
func take_damage(amount: int) -> void:
	if health <= 0:
		return
	
	health = max(health - amount, 0)
	
	# Stop any previous hit flash.
	if hit_tween != null and hit_tween.is_running():
		hit_tween.kill()
	
	# Brief cyan-white flash when struck.
	crate_visual.modulate = Color("#CFFFFF")
	
	hit_tween = create_tween()
	hit_tween.tween_property(
		crate_visual,
		"modulate",
		Color.WHITE,
		0.10
	)
	
	if health <= 0:
		# Disable collision before removing the crate.
		collision_shape.set_deferred("disabled", true)
		
		# Shrink and fade when destroyed.
		hit_tween.tween_property(
			crate_visual,
			"scale",
			Vector2(0.75, 0.75),
			0.16
		)
		
		hit_tween.parallel().tween_property(
			crate_visual,
			"modulate:a",
			0.0,
			0.16
		)
		
		hit_tween.tween_callback(_spawn_salvage)
		hit_tween.tween_callback(queue_free)

func _spawn_salvage() -> void:
	print("CRATE DROP FUNCTION CALLED")
	
	var pickup: Area2D = SALVAGE_PICKUP_SCENE.instantiate() as Area2D
	
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position
