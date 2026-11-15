
class_name TurnManager
extends Node

signal turn_started(player_index: int, turn_number: int)

enum Phase {
	PRE_SHOT,
	BALL_IN_MOTION,
	POST_SHOT
}

@export_range(0.1, 120.0, 0.1)
var post_shot_duration: float = 5.0

@onready var balls: Array[GolfBall] = [
	$"../GolfBall",
	$"../GolfBall2"
]

@onready var end_turn_timer: Timer = $EndTurnTimer
@onready var reaction_manager: ReactionManager = $"../ReactionManager"
@onready var ability_manager: AbilityManager = $"../AbilityManager"

var current_player: int = 0
var turn_number: int = 1
var phase: Phase = Phase.PRE_SHOT


func _ready() -> void:
	end_turn_timer.one_shot = true
	end_turn_timer.paused = false
	end_turn_timer.timeout.connect(_on_end_turn_timeout)

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
	return (
		phase == Phase.PRE_SHOT
		and not reaction_manager.is_reaction_open
	)


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

	phase = Phase.POST_SHOT

	end_turn_timer.paused = false
	end_turn_timer.start(post_shot_duration)

	print("[PHASE] POST_SHOT")
	print(
		"[TURN] Auto-ending in ",
		post_shot_duration,
		" seconds"
	)


func _on_end_turn_timeout() -> void:
	_end_turn()


func _end_turn() -> void:
	if reaction_manager.is_reaction_open:
		print("[REJECTED] Close the reaction window first")
		return

	if phase != Phase.POST_SHOT:
		print("[REJECTED] Cannot end turn yet")
		return

	end_turn_timer.stop()
	end_turn_timer.paused = false

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

	turn_started.emit(current_player, turn_number)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_1:
			ability_manager.try_play_ability(
				current_player,
				"freeze_green"
			)

		KEY_2:
			ability_manager.try_play_ability(
				current_player,
				"repair_club"
			)

		KEY_Q:
			ability_manager.try_play_ability(
				0,
				"sudden_gust"
			)

		KEY_E:
			ability_manager.try_play_ability(
				1,
				"sudden_gust"
			)

		KEY_SPACE:
			_end_turn()
