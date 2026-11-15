
class_name TurnManager
extends Node

signal turn_started(player_index: int, turn_number: int)

enum Phase {
	PRE_SHOT,
	BALL_IN_MOTION,
	POST_SHOT,
	HOLE_COMPLETE
}

@export_range(0.1, 120.0, 0.1)
var post_shot_duration: float = 5.0

# Our proposed rule. Disable for traditional golf order.
@export var closest_plays_first: bool = true

@onready var balls: Array[GolfBall] = [
	$"../GolfBall",
	$"../GolfBall2"
]

@onready var golf_hole: GolfHole = $"../GolfHole"
@onready var end_turn_timer: Timer = $EndTurnTimer
@onready var reaction_manager: ReactionManager = $"../ReactionManager"
@onready var ability_manager: AbilityManager = $"../AbilityManager"

var current_player: int = 0
var turn_number: int = 1
var phase: Phase = Phase.PRE_SHOT

# Strokes taken on the current hole.
var strokes: Array[int] = [0, 0]


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
		and not golf_hole.holed_balls[current_player]
		and not reaction_manager.is_reaction_open
	)


func _on_shot_started(player_index: int) -> void:
	if player_index != current_player:
		return

	if phase != Phase.PRE_SHOT:
		return

	strokes[player_index] += 1
	phase = Phase.BALL_IN_MOTION

	print(
		"[SHOT] Player ",
		player_index + 1,
		" | Stroke ",
		strokes[player_index]
	)


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

	# Both golfers have finished the hole.
	if _both_players_holed():
		_complete_hole()
		return

	current_player = _get_next_player()
	turn_number += 1
	phase = Phase.PRE_SHOT

	_announce_turn()


func _get_next_player() -> int:
	var player_1_holed: bool = golf_hole.holed_balls[0]
	var player_2_holed: bool = golf_hole.holed_balls[1]

	# A completed golfer cannot shoot again.
	if player_1_holed:
		return 1

	if player_2_holed:
		return 0

	# Both golfers must take their tee shots.
	if strokes[0] == 0:
		return 0

	if strokes[1] == 0:
		return 1

	# After tee shots, compare distances to the cup.
	var distance_1: float = balls[0].global_position.distance_to(
		golf_hole.global_position
	)

	var distance_2: float = balls[1].global_position.distance_to(
		golf_hole.global_position
	)

	if is_equal_approx(distance_1, distance_2):
		# Alternate when distances are equal.
		return (current_player + 1) % 2

	if closest_plays_first:
		if distance_1 < distance_2:
			return 0
		return 1

	# Traditional golf: farthest ball plays first.
	if distance_1 > distance_2:
		return 0

	return 1


func _both_players_holed() -> bool:
	return (
		golf_hole.holed_balls[0]
		and golf_hole.holed_balls[1]
	)


func _complete_hole() -> void:
	phase = Phase.HOLE_COMPLETE

	print("")
	print("========== HOLE COMPLETE ==========")
	print("Player 1 strokes: ", strokes[0])
	print("Player 2 strokes: ", strokes[1])

	if strokes[0] < strokes[1]:
		print("[RESULT] Player 1 wins the hole")
	elif strokes[1] < strokes[0]:
		print("[RESULT] Player 2 wins the hole")
	else:
		print("[RESULT] Hole halved")

	print("===================================")


func _announce_turn() -> void:
	print("")
	print("==============================")
	print("[TURN ", turn_number, "] Player ", current_player + 1)
	print("[PHASE] PRE_SHOT")
	print("[STROKES] P1: ", strokes[0], " | P2: ", strokes[1])
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
