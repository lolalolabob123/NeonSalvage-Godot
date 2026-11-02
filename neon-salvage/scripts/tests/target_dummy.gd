extends StaticBody2D

const BASE_COLOR: Color = Color("#C04D5B")
const HIT_COLOR: Color = Color("#F8FBFF")

@onready var visual: ColorRect = $ColorRect

var health: int = 4
var flash_tween: Tween

func take_damage(amount: int) -> void:
	health -= amount
	print("Target health: ", health)
	
	# Stop an existing flash before starting another.
	if flash_tween != null and flash_tween.is_running():
		flash_tween.kill()	
	
	#Flash bright white on impact
	visual.color = HIT_COLOR
	
	#Return smoothly to the normal colour.
	flash_tween = create_tween()
	flash_tween.tween_property(
		visual,
		"color",
		BASE_COLOR,
		0.12
	)
	
	#Let the final hit flash finish before removing the target.
	if health <= 0:
		flash_tween.finished.connect(queue_free)
