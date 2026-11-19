extends Area2D

@export var mission_controller: FacilityMission
@export var restart_duration: float = 12.0
@export var control_radius: float = 180.0
@export var interaction_radius: float = 80.0

@onready var interaction_prompt: Label = $InteractionPrompt
@onready var status_strip: Polygon2D = $Panel/StatusStrip
@onready var progress_label: Label = $ProgressLabel

var restart_progress: float = 0.0

func _ready() -> void:
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(mission_controller):
		interaction_prompt.hide()
		progress_label.hide()
		progress_label.text = "Mission controller not assigned."
		return
	
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var alive := (
		is_instance_valid(player)
		and int(player.get("current_health")) > 0
	)
	var distance: float = INF
	if alive:
		distance = global_position.distance_to(player.global_position)
	
	interaction_prompt.visible = alive and distance <= interaction_radius
	status_strip.color = Color("#F3AC57")
	
	if mission_controller.turbine_running:
		status_strip.color = Color("#B6FFD0")
		interaction_prompt.text = "TURBINE RUNNING"
		progress_label.text = "STATION POWER RESTORED"
	elif mission_controller.turbine_startup_active:
		interaction_prompt.text = "RESTART IN PROGRESS"
		var in_range := alive and distance <= control_radius
		if in_range:
			restart_progress = minf(
				restart_progress + delta,
				maxf(restart_duration, 0.1)
			)
		var percentage := floori(
			100.0 * restart_progress / maxf(restart_duration, 0.1)
		)
		if in_range:
			progress_label.text = "RESTART %d%% — STAY IN THE RING" % percentage
		else:
			progress_label.text = "PAUSED %d%% — RETURN TO THE RING" % percentage
		
		if restart_progress >= maxf(restart_duration, 0.1):
			if mission_controller.start_turbine():
				progress_label.text = "STATION POWER RESTORED"
	else:
		interaction_prompt.text = "[E] BEGIN TURBINE RESTART"

		if mission_controller.turbine_circuit_isolated:
			progress_label.text = "DISCHARGES ISOLATED — RESTART READY"
		else:
			progress_label.text = "MANUAL CONTROL AREA"
	
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	if not is_instance_valid(mission_controller):
		return
	
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return
	if int(player.get("current_health")) <= 0:
		return
	if global_position.distance_to(player.global_position) > interaction_radius:
		return
	
	if mission_controller.begin_turbine_restart():
		get_viewport().set_input_as_handled()
	
func _draw() -> void:
	var ring_color := Color("#31CBE0")
	if is_instance_valid(mission_controller):
		if mission_controller.turbine_running:
			ring_color = Color("#B6FFD0")
	
	draw_circle(Vector2.ZERO, control_radius, Color(0.19, 0.80, 0.88, 0.035))
	draw_arc(Vector2.ZERO, control_radius, 0.0, TAU, 96, ring_color, 2.0, true)
	var fraction := clampf(restart_progress / maxf(restart_duration, 0.1), 0.0, 1.0)
	if fraction > 0.0:
		draw_arc(
			Vector2.ZERO, control_radius - 5.0,
			-PI * 0.5, -PI * 0.5 + TAU * fraction,
			96, Color("#B6FFD0"), 4.0, true
		)
