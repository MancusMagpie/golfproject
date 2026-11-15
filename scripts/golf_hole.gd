
class_name GolfHole
extends Node2D

signal ball_holed(player_index: int)

@export var cup_radius: float = 9.0
@export var cup_color: Color = Color("#192d20")

@export var flag_height: float = 30.0
@export var flag_color: Color = Color("#ff6b6b")

# Maximum ball speed at which it can fall in.
@export var max_capture_speed: float = 180.0

@onready var balls: Array[GolfBall] = [
	$"../GolfBall",
	$"../GolfBall2"
]

# Track which balls have already been captured.
var holed_balls: Array[bool] = [false, false]


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Draw the cup.
	draw_circle(
		Vector2.ZERO,
		cup_radius,
		cup_color
	)

	# Draw the flagpole.
	draw_line(
		Vector2.ZERO,
		Vector2(0, -flag_height),
		Color.WHITE,
		2.0
	)

	# Draw the flag.
	var flag_points := PackedVector2Array([
		Vector2(0, -flag_height),
		Vector2(18, -flag_height + 6),
		Vector2(0, -flag_height + 12)
	])

	draw_colored_polygon(flag_points, flag_color)


func _physics_process(_delta: float) -> void:
	for player_index in range(balls.size()):
		if holed_balls[player_index]:
			continue

		var ball: GolfBall = balls[player_index]

		# Only capture moving balls.
		if not ball.is_moving:
			continue

		if ball.simulation_paused:
			continue

		var distance: float = ball.global_position.distance_to(
			global_position
		)

		# Ball must be inside the cup.
		if distance > cup_radius:
			continue

		# Fast-moving balls roll over the cup.
		if ball.velocity.length() > max_capture_speed:
			continue

		_capture_ball(ball, player_index)


func _capture_ball(
	ball: GolfBall,
	player_index: int
) -> void:
	holed_balls[player_index] = true

	# Stop the ball and position it in the cup.
	ball.velocity = Vector2.ZERO
	ball.is_moving = false
	ball.global_position = global_position

	# Inform the existing turn system.
	ball.shot_finished.emit()

	print(
		"[HOLE] Player ",
		player_index + 1,
		" has sunk their ball!"
	)

	ball_holed.emit(player_index)
