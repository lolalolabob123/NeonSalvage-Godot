extends Node2D

@export var mission_controller: FacilityMission
@export var strip_width: float = 400
@export var strip_height: float = 72.0
@export var lane_count: int = 5
@export var warning_duration: float = 1.0
@export var live_duration: float = 0.6
@export var safe_duration: float = 0.4

var elapsed: float = 0.0
var current_lane: int = 0
var current_phase: int = 0 # # 0 = warning, 1 = live, 2 = safe

func _ready() -> void:
	z_index = -2
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(mission_controller):
		return
	
	if not mission_controller.turbine_startup_active:
		elapsed = 0.0
		queue_redraw()
		return
	
	elapsed += delta
	var warning := maxf(warning_duration, 0.1)
	var live := maxf(live_duration, 0.1)
	var cycle := warning + live + maxf(safe_duration, 0.0)
	current_lane = floori(elapsed / cycle) % maxi(lane_count, 1)
	var phase_time := fmod(elapsed, cycle)
	
	if phase_time < warning:
		current_phase = 0
	elif phase_time < warning + live:
		current_phase = 1
	else:
		current_phase = 2
	
	if current_phase == 1:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if is_instance_valid(player):
			if _lane_rect(current_lane).has_point(to_local(player.global_position)):
				player.call("take_damage", 1)
	
	queue_redraw()

func _lane_rect(index: int) -> Rect2:
	var total_height := float(maxi(lane_count, 1)) * strip_height

	return Rect2(
		Vector2(
			-strip_width * 0.5,
			-total_height * 0.5 + index * strip_height
		),
		Vector2(strip_width, strip_height)
	)


func _draw() -> void:
	for index in range(maxi(lane_count, 1)):
		draw_rect(
			_lane_rect(index),
			Color(0.20, 0.45, 0.50, 0.25),
			false,
			1.0
		)

	if not is_instance_valid(mission_controller):
		return

	if not mission_controller.turbine_startup_active:
		return

	var band := _lane_rect(current_lane)

	if current_phase == 0:
		var pulse := 0.20 + 0.15 * absf(sin(elapsed * 12.0))
		draw_rect(band, Color(0.95, 0.67, 0.34, pulse))
		draw_rect(band, Color("#F3AC57"), false, 3.0)

	elif current_phase == 1:
		draw_rect(band, Color(1.0, 0.25, 0.35, 0.55))
		draw_rect(band, Color("#FF8090"), false, 3.0)

		for line_index in range(3):
			var line_y := (
				band.position.y
				+ strip_height * float(line_index + 1) / 4.0
			)

			draw_line(
				Vector2(band.position.x, line_y),
				Vector2(band.end.x, line_y),
				Color("#FFE6EC"),
				2.0,
				true
			)
