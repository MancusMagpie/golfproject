
class_name TurnManager
extends Node

enum Phase {
	PRE_SHOT,
	BALL_IN_MOTION,
	POST_SHOT
}

# Duration of the post-shot phase in seconds.
@export_range(0.1, 120.0, 0.1)
var post_shot_duration: float = 5.0

# References to the two player balls.
@onready var balls: Array[GolfBall] = [
	$"../GolfBall",
	$"../GolfBall2"
]

# Timer must be a child of TurnManager.
@onready var end_turn_timer: Timer = $EndTurnTimer
@onready var reaction_manager: ReactionManager = $"../ReactionManager"

var current_player: int = 0
var turn_number: int = 1
var phase: Phase = Phase.PRE_SHOT


func _ready() -> void:
	# Configure the countdown timer.
	end_turn_timer.one_shot = true
	end_turn_timer.timeout.connect(_on_end_turn_timeout)

	# Connect signals from both balls.
	for i in range(balls.size()):
		balls[i].shot_started.connect(
			_on_shot_started.bind(i)
		)

		balls[i].shot_finished.connect(
			_on_shot_finished.bind(i)
		)

	_announce_turn()


func get_active_ball() -> GolfBall:
	return balls[current_player]


func can_shoot() -> bool:
	return phase == Phase.PRE_SHOT


func _on_shot_started(player_index: int) -> void:
	if player_index != current_player:
		return

	if phase != Phase.PRE_SHOT:
		return

	phase = Phase.BALL_IN_MOTION

	print("[SHOT] Player ", current_player + 1, " shoots")
	print("[PHASE] BALL_IN_MOTION")


func _on_shot_finished(player_index: int) -> void:
	if player_index != current_player:
		return

	if phase != Phase.BALL_IN_MOTION:
		return

	# Enter the post-shot phase.
	phase = Phase.POST_SHOT

	print("[PHASE] POST_SHOT")

	# Start the configurable countdown.
	end_turn_timer.start(post_shot_duration)

	print(
		"[TURN] Auto-ending in ",
		post_shot_duration,
		" seconds. Press SPACE to end early."
	)


func _on_end_turn_timeout() -> void:
	print("[TURN] Post-shot timer expired")
	_end_turn()


func _end_turn() -> void:
	if reaction_manager.is_reaction_open:
		print("[REJECTED] Close reaction window first")
		return
		
	if phase != Phase.POST_SHOT:
		print("[REJECTED] Cannot end turn yet")
		return

	# Stop the timer if manually ending early.
	end_turn_timer.stop()

	# Alternate between players.
	current_player = (current_player + 1) % balls.size()

	turn_number += 1
	phase = Phase.PRE_SHOT

	_announce_turn()


func _announce_turn() -> void:
	print("")
	print("==============================")
	print("[TURN ", turn_number, "] Player ", current_player + 1)
	print("[PHASE] PRE_SHOT")
	print("==============================")


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_1:
			_try_ability(
				current_player,
				"Freeze Green",
				Phase.PRE_SHOT
			)

		KEY_2:
			_try_ability(
				current_player,
				"Repair Club",
				Phase.POST_SHOT
			)

		KEY_Q:
			_try_instant(
				0,
				"Sudden Gust"
			)

		KEY_E:
			_try_instant(
				1,
				"Sudden Gust"
			)

		KEY_SPACE:
			_end_turn()


func _try_ability(
	player_index: int,
	ability_name: String,
	required_phase: Phase
) -> void:
	if phase != required_phase:
		print(
			"[REJECTED] ",
			ability_name,
			" cannot be used during ",
			Phase.keys()[phase]
		)
		return

	print(
		"[ABILITY] Player ",
		player_index + 1,
		" activated ",
		ability_name,
		" during ",
		Phase.keys()[phase]
	)


func _try_instant(
	player_index: int,
	ability_name: String
) -> void:
	# Instants are allowed during any phase
	# and on either player's turn.
	print(
		"[INSTANT] Player ",
		player_index + 1,
		" activated ",
		ability_name,
		" during Player ",
		current_player + 1,
		"'s turn (",
		Phase.keys()[phase],
		")"
	)
