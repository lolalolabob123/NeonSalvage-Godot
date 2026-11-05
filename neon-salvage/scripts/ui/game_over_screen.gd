extends CanvasLayer

@onready var restart_button: Button = $ContentCenter/Content/RestartButton
@onready var dim_background: ColorRect = $DimBackground
@onready var content_center: CenterContainer = $ContentCenter

func _ready() -> void:
	# Hide the screen until the player is destroyed.
	hide()
	
	restart_button.pressed.connect(_on_restart_pressed)
	
	# Find the player and listen for destruction.
	var player: Node = get_tree().get_first_node_in_group("player")
	
	if player != null and player.has_signal("player_destroyed"):
		player.connect("player_destroyed", _on_player_destroyed)

func _on_player_destroyed() -> void:
	# Make both elements initially transparent.
	dim_background.modulate = Color(1.0, 1.0, 1.0, 0.0)
	content_center.modulate = Color(1.0, 1.0, 1.0, 0.0)
	
	# Display the Game Over Layer.
	show()
	
	# Create the fade-in animation.
	var fade_tween: Tween = create_tween()
	fade_tween.set_parallel(true)
	
	# Fade in the dark background
	fade_tween.tween_property(
		dim_background,
		"modulate",
		Color.WHITE,
		0.35
	)
	
	# Fade in the title and restart button slightly later.
	fade_tween.tween_property(
		content_center,
		"modulate",
		Color.WHITE,
		0.45
	).set_delay(0.1)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
