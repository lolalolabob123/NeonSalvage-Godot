extends Sprite2D

@export var pulse_period: float = 2.6

var elapsed: float = 0.0


func _process(delta: float) -> void:
	elapsed += delta

	var wave := 0.5 + 0.5 * sin(
		elapsed * TAU / maxf(pulse_period, 0.1)
	)

	self_modulate.a = lerpf(0.65, 1.0, wave)
