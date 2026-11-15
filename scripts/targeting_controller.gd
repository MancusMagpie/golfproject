
class_name TargetingController
extends Node2D

signal target_selected(
	ability_id: String,
	target_type: int,
	target_data: Dictionary
)

signal targeting_cancelled

@onready var balls: Array[GolfBall] = [
	$"../GolfBall",
	$"../GolfBall2"
]

@export var ball_selection_radius: float = 20.0

var is_targeting: bool = false
var current_ability: GolfAbility = null


func begin_targeting(ability: GolfAbility) -> void:
	if ability == null:
		return

	current_ability = ability
	is_targeting = true

	print(
		"[TARGETING] Select target for ",
		ability.ability_name
	)

	if ability.target_type == GolfAbility.TargetType.NONE:
		_confirm_target({})

	elif ability.target_type == GolfAbility.TargetType.GAME:
		# Game-level effects do not need a map click.
		_confirm_target({"scope": "match"})

	elif ability.target_type == GolfAbility.TargetType.GOLFER:
		print("[TARGETING] Golfer selection required")

	else:
		print("[TARGETING] Left-click to select target")


func _unhandled_input(event: InputEvent) -> void:
	if not is_targeting:
		return

	if not event is InputEventMouseButton:
		return

	if not event.pressed:
		return

	if event.button_index == MOUSE_BUTTON_RIGHT:
		cancel_targeting()
		get_viewport().set_input_as_handled()
		return

	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	match current_ability.target_type:
		GolfAbility.TargetType.BALL:
			_select_ball()

		GolfAbility.TargetType.COURSE_AREA:
			_select_course_area()

	get_viewport().set_input_as_handled()


func _select_ball() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()

	for player_index in range(balls.size()):
		var ball: GolfBall = balls[player_index]

		if mouse_pos.distance_to(
			ball.global_position
		) <= ball_selection_radius:

			_confirm_target({
				"player_index": player_index,
				"ball": ball
			})
			return

	print("[TARGETING] No ball selected")


func _select_course_area() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()

	_confirm_target({
		"position": mouse_pos
	})


func select_golfer(player_index: int) -> void:
	if not is_targeting:
		return

	if current_ability.target_type != GolfAbility.TargetType.GOLFER:
		return

	if player_index < 0 or player_index >= balls.size():
		return

	_confirm_target({
		"player_index": player_index
	})


func _confirm_target(target_data: Dictionary) -> void:
	if current_ability == null:
		return

	print(
		"[TARGETING] Target selected for ",
		current_ability.ability_name,
		": ",
		target_data
	)

	target_selected.emit(
		current_ability.ability_id,
		current_ability.target_type,
		target_data
	)

	is_targeting = false
	current_ability = null


func cancel_targeting() -> void:
	if not is_targeting:
		return

	is_targeting = false
	current_ability = null

	print("[TARGETING] Selection cancelled")

	targeting_cancelled.emit()
