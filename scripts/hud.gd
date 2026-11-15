
extends CanvasLayer

@onready var turn_manager: TurnManager = $"../TurnManager"
@onready var reaction_manager: ReactionManager = $"../ReactionManager"
@onready var turn_label: Label = $TurnLabel


func _process(_delta: float) -> void:
	var player_number: int = turn_manager.current_player + 1

	var phase_name: String = TurnManager.Phase.keys()[
		turn_manager.phase
	]

	var display_text: String = "Player %d | %s" % [
		player_number,
		phase_name
	]

	# Show the post-shot countdown.
	if turn_manager.phase == TurnManager.Phase.POST_SHOT:
		var remaining: float = turn_manager.end_turn_timer.time_left
		display_text += " | %.1fs" % remaining

	# Show reaction ownership and remaining time.
	if reaction_manager.is_reaction_open:
		var reaction_player: int = reaction_manager.reaction_player + 1
		var reaction_remaining: float = (
			reaction_manager.reaction_timer.time_left
		)

		display_text += " | P%d REACTION: %.1fs" % [
			reaction_player,
			reaction_remaining
		]

	turn_label.text = display_text
