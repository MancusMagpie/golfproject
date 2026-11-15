
class_name GolfBall
extends Node2D

signal shot_started
signal shot_finished

@export var friction: float = 320.0
@export var stop_threshold: float = 8.0
@export var radius: float = 6.0

@export var ball_color: Color = Color.WHITE

@export var play_bounds: Rect2 = Rect2(
	0.0, 0.0, 640.0, 360.0
)
@export_range(0.0, 1.0) var wall_bounce: float = 0.5

var velocity: Vector2 = Vector2.ZERO
var is_moving: bool = false
var simulation_paused: bool = false


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, ball_color)


func _physics_process(delta: float) -> void:
	if not is_moving or simulation_paused:
		return

	position += velocity * delta

	_handle_boundaries()

	velocity = velocity.move_toward(
		Vector2.ZERO,
		friction * delta
	)

	if velocity.length() <= stop_threshold:
		velocity = Vector2.ZERO
		is_moving = false
		shot_finished.emit()

		print("[BALL] Stopped at: ", global_position)


func _handle_boundaries() -> void:
	var min_x := play_bounds.position.x + radius
	var max_x := play_bounds.end.x - radius
	var min_y := play_bounds.position.y + radius
	var max_y := play_bounds.end.y - radius

	if position.x < min_x:
		position.x = min_x
		velocity.x = abs(velocity.x) * wall_bounce

	elif position.x > max_x:
		position.x = max_x
		velocity.x = -abs(velocity.x) * wall_bounce

	if position.y < min_y:
		position.y = min_y
		velocity.y = abs(velocity.y) * wall_bounce

	elif position.y > max_y:
		position.y = max_y
		velocity.y = -abs(velocity.y) * wall_bounce

func pause_simulation() -> void:
	simulation_paused = true


func resume_simulation() -> void:
	simulation_paused = false

func launch(direction: Vector2, power: float) -> void:
	if is_moving:
		return

	if direction.length_squared() == 0.0:
		return

	velocity = direction.normalized() * power
	is_moving = true

	shot_started.emit()
