
class_name ReactionManager
extends Node

signal reaction_window_opened(player_id: int)
signal reaction_window_closed

@export_range(1.0, 120.0, 1.0)
var reaction_duration: float = 30.0

@onready var turn_manager: TurnManager = $"../TurnManager"

@onready var balls: Array[GolfBall] = [
	$"../GolfBall",
	$"../GolfBall2"
]

var is_reaction_open: bool = false
var reaction_player: int = -1

# One opportunity per player, per phase, per shot.
var used_in_flight: Array[bool] = [false, false]
var used_post_shot: Array[bool] = [false]

var tracked_turn: int = -1
var reaction_timer: Timer


func _ready() -> void:
	# Create our reaction countdown timer.
	reaction_timer = Timer.new()
	reaction_timer.name = "ReactionTimer"
	reaction_timer.one_shot = true
	reaction_timer.process_callback = Timer.TIMER_PROCESS_IDLE

	add_child(reaction_timer)

	reaction_timer.timeout.connect(
		_on_reaction_timeout
	)

	reaction_window_opened.connect(
		_on_reaction_opened
	)

	reaction_window_closed.connect(
		_on_reaction_closed
	)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_F:
			toggle_reaction_window(0)

		KEY_R:
			toggle_reaction_window(1)


func toggle_reaction_window(player_index: int) -> void:
	if is_reaction_open:
		if reaction_player == player_index:
			close_reaction_window()
		else:
			print(
				"[REJECTED] Player ",
				reaction_player + 1,
				" already owns the reaction window"
			)
		return

	open_reaction_window(player_index)


func open_reaction_window(player_index: int) -> void:
	_reset_usage_if_new_turn()

	if is_reaction_open:
		return

	var phase: TurnManager.Phase = turn_manager.phase

	if phase == TurnManager.Phase.PRE_SHOT:
		print("[REJECTED] Cannot open a reaction before a shot")
		return

	if phase == TurnManager.Phase.BALL_IN_MOTION:
		if used_in_flight[player_index]:
			print(
				"[REJECTED] Player ",
				player_index + 1,
				" already used their in-flight reaction"
			)
			return

		used_in_flight[player_index] = true

	elif phase == TurnManager.Phase.POST_SHOT:
		if used_post_shot[player_index]:
			print(
				"[REJECTED] Player ",
				player_index + 1,
				" already used their post-shot reaction"
			)
			return

		used_post_shot[player_index] = true

	else:
		return

	is_reaction_open = true
	reaction_player = player_index

	# Freeze the post-shot timer if it is running.
	if phase == TurnManager.Phase.POST_SHOT:
		turn_manager.end_turn_timer.paused = true

	# Start the reaction window countdown.
	reaction_timer.start(reaction_duration)

	print(
		"[REACTION] Player ",
		player_index + 1,
		" opened a reaction window during ",
		TurnManager.Phase.keys()[phase]
	)

	print(
		"[REACTION] Window closes in ",
		reaction_duration,
		" seconds"
	)

	reaction_window_opened.emit(player_index)


func close_reaction_window() -> void:
	if not is_reaction_open:
		return

	reaction_timer.stop()

	is_reaction_open = false

	# Resume the normal post-shot timer.
	turn_manager.end_turn_timer.paused = false

	print("[REACTION] Window closed — simulation resumed")

	reaction_window_closed.emit()

	reaction_player = -1


func _on_reaction_timeout() -> void:
	if not is_reaction_open:
		return

	print("[REACTION] 30-second reaction window expired")

	close_reaction_window()


func _reset_usage_if_new_turn() -> void:
	if tracked_turn == turn_manager.turn_number:
		return

	tracked_turn = turn_manager.turn_number

	used_in_flight = [false, false]
	used_post_shot = [false, false]


func _on_reaction_opened(_player_id: int) -> void:
	for ball in balls:
		ball.pause_simulation()


func _on_reaction_closed() -> void:
	for ball in balls:
		ball.resume_simulation()
