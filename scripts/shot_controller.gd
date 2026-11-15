
extends Node2D

@export var max_pull_distance: float = 110.0
@export var power_multiplier: float = 5.0
@export var min_pull_distance: float = 5.0
@export var click_radius: float = 25.0

@onready var turn_manager: TurnManager = $"../TurnManager"
@onready var targeting_controller = $"../TargetingController"

var is_dragging: bool = false
var drag_position: Vector2 = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	# Target selection takes priority over shooting.
	if targeting_controller.is_targeting:
		if is_dragging:
			_cancel_aiming()
		return

	if event is InputEventMouseButton:

		# Right-click cancels the current shot.
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and is_dragging:
				_cancel_aiming()
			return

		# Left-click begins or releases a shot.
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_aiming()
			elif is_dragging:
				_release_shot()

	elif event is InputEventMouseMotion and is_dragging:
		drag_position = get_global_mouse_position()
		queue_redraw()


func _start_aiming() -> void:
	# Do not aim while selecting an ability target.
	if targeting_controller.is_targeting:
		return

	if not turn_manager.can_shoot():
		return

	var ball: GolfBall = turn_manager.get_active_ball()

	if ball.is_moving:
		return

	var mouse_pos: Vector2 = get_global_mouse_position()

	if mouse_pos.distance_to(ball.global_position) > click_radius:
		return

	is_dragging = true
	drag_position = mouse_pos
	queue_redraw()


func _cancel_aiming() -> void:
	is_dragging = false
	drag_position = Vector2.ZERO
	queue_redraw()

	print("[SHOT] Aiming cancelled")


func _release_shot() -> void:
	is_dragging = false

	if targeting_controller.is_targeting:
		queue_redraw()
		return

	if not turn_manager.can_shoot():
		queue_redraw()
		return

	var ball: GolfBall = turn_manager.get_active_ball()

	drag_position = get_global_mouse_position()

	var pull_vector: Vector2 = (
		ball.global_position - drag_position
	)

	# Ignore tiny accidental drags.
	if pull_vector.length() < min_pull_distance:
		queue_redraw()
		return

	var pull_distance: float = min(
		pull_vector.length(),
		max_pull_distance
	)

	var direction: Vector2 = pull_vector.normalized()
	var power: float = pull_distance * power_multiplier

	queue_redraw()
	ball.launch(direction, power)


func _draw() -> void:
	if not is_dragging:
		return

	var ball: GolfBall = turn_manager.get_active_ball()
	var ball_pos: Vector2 = to_local(ball.global_position)

	var pull_vector: Vector2 = (
		ball.global_position - drag_position
	)

	if pull_vector.length() == 0.0:
		return

	var pull_distance: float = min(
		pull_vector.length(),
		max_pull_distance
	)

	var direction: Vector2 = pull_vector.normalized()

	# White line: pull-back direction.
	var pull_end: Vector2 = (
		ball_pos - direction * pull_distance
	)

	draw_line(
		ball_pos,
		pull_end,
		Color.WHITE,
		2.0
	)

	# Yellow line: intended shot direction.
	var aim_end: Vector2 = (
		ball_pos + direction * pull_distance * 1.5
	)

	draw_line(
		ball_pos,
		aim_end,
		Color.YELLOW,
		3.0
	)

	draw_circle(aim_end, 3.0, Color.YELLOW)
