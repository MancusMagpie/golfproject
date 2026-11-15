
class_name ReactionManager
extends Node

signal reaction_window_opened(player_id: int)
signal reaction_window_closed

@export_range(1.0, 120.0, 1.0)
var reaction_duration: float = 30.0

@onready var turn_manager: TurnManager = $"../TurnManager"
@onready var ability_manager: AbilityManager = $"../AbilityManager"

@onready var balls: Array[GolfBall] = [
	$"../GolfBall",
	$"../GolfBall2"
]

var is_reaction_open: bool = false
var reaction_player: int = -1

# Track empty reactions for future penalties.
var consecutive_empty_reactions: Array[int] = [0, 0]
var cards_played_this_window: int = 0

var reaction_timer: Timer


func _ready() -> void:
	reaction_timer = Timer.new()
	reaction_timer.name = "ReactionTimer"
	reaction_timer.one_shot = true
	add_child(reaction_timer)

	reaction_timer.timeout.connect(_on_reaction_timeout)
	reaction_window_opened.connect(_on_reaction_opened)
	reaction_window_closed.connect(_on_reaction_closed)


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
			print("[REJECTED] Another player's reaction is open")
		return

	open_reaction_window(player_index)


func open_reaction_window(player_index: int) -> void:
	if is_reaction_open:
		return

	var phase: TurnManager.Phase = turn_manager.phase

	if phase == TurnManager.Phase.PRE_SHOT:
		print("[REJECTED] Reactions unavailable before shooting")
		return

	if player_index < 0 or player_index >= 2:
		return

	# Only allow reactions with an eligible instant in hand.
	if not ability_manager.has_playable_instant(player_index, phase):
		print(
			"[REJECTED] Player ",
			player_index + 1,
			" has no playable instant"
		)
		return

	is_reaction_open = true
	reaction_player = player_index
	cards_played_this_window = 0

	if phase == TurnManager.Phase.POST_SHOT:
		turn_manager.end_turn_timer.paused = true

	reaction_timer.start(reaction_duration)

	print(
		"[REACTION] Player ",
		player_index + 1,
		" opened a reaction during ",
		TurnManager.Phase.keys()[phase]
	)

	reaction_window_opened.emit(player_index)


func record_card_played(player_index: int) -> void:
	if not is_reaction_open:
		return

	if player_index != reaction_player:
		return

	cards_played_this_window += 1

	print(
		"[REACTION] Player ",
		player_index + 1,
		" played an instant — resuming simulation"
	)

	# Automatically resume gameplay after the instant is played.
	close_reaction_window()


func close_reaction_window() -> void:
	if not is_reaction_open:
		return

	var closing_player: int = reaction_player

	reaction_timer.stop()
	is_reaction_open = false

	turn_manager.end_turn_timer.paused = false

	if cards_played_this_window == 0:
		consecutive_empty_reactions[closing_player] += 1

		print(
			"[REACTION] Empty reaction | Player ",
			closing_player + 1,
			" | Consecutive empty windows: ",
			consecutive_empty_reactions[closing_player]
		)
	else:
		consecutive_empty_reactions[closing_player] = 0
		print("[REACTION] Valid reaction — gameplay resumed")

	reaction_window_closed.emit()

	reaction_player = -1
	cards_played_this_window = 0


func _on_reaction_timeout() -> void:
	if not is_reaction_open:
		return

	print("[REACTION] Reaction timer expired")
	close_reaction_window()


func _on_reaction_opened(_player_id: int) -> void:
	for ball in balls:
		ball.pause_simulation()


func _on_reaction_closed() -> void:
	for ball in balls:
		ball.resume_simulation()
