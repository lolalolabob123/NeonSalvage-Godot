extends Node2D

const SPARK_COUNT: int = 8
const DURATION: float = 0.22

func _ready() -> void:
	for i in range(SPARK_COUNT):
		var angle: float = (
			TAU * float(i) / float(SPARK_COUNT)
			+ randf_range(-0.18, 0.18)
		)
		
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var distance: float = randf_range(12.0, 24.0)
		
		var spark := Line2D.new()
		spark.points = PackedVector2Array([
			Vector2.ZERO,
			Vector2(-6.0, 0.0)
		])
		spark.width = 1.8
		spark.default_color = (
			Color("#C9FDFF") if i % 3  == 0
			else Color("#2CE6F1")
		)
		spark.antialiased = true
		spark.rotation = angle
		add_child(spark)
		
		var tween: Tween = create_tween().set_parallel(true)
		
		tween.tween_property(
			spark,
			"position",
			direction * distance,
			DURATION
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		tween.tween_property(
			spark,
			"modulate:a",
			0.0,
			DURATION
		)

	get_tree().create_timer(DURATION + 0.02).timeout.connect(queue_free)
