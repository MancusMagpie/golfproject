
extends CanvasLayer

@onready var turn_manager: TurnManager = $"../TurnManager"
@onready var reaction_manager: ReactionManager = $"../ReactionManager"
@onready var ability_manager: AbilityManager = $"../AbilityManager"
@onready var turn_label: Label = $TurnLabel


func _process(_delta: float) -> void:
	var player_index: int = turn_manager.current_player
	var player_number: int = player_index + 1

	var phase_name: String = TurnManager.Phase.keys()[
		turn_manager.phase
	]

	var display_text: String = "Player %d | %s" % [
		player_number,
		phase_name
	]

	# Show current player's hand size.
	var hand_size: int = ability_manager.hands[player_index].size()
	var max_hand_size: int = ability_manager.max_hand_size

	display_text += " | Cards: %d/%d" % [
		hand_size,
		max_hand_size
	]

	# Show remaining post-shot countdown.
	if turn_manager.phase == TurnManager.Phase.POST_SHOT:
		var remaining: float = turn_manager.end_turn_timer.time_left
		display_text += " | %.1fs" % remaining

	# Show reaction window owner and countdown.
	if reaction_manager.is_reaction_open:
		var reacting_player: int = reaction_manager.reaction_player + 1
		var reaction_remaining: float = (
			reaction_manager.reaction_timer.time_left
		)

		display_text += "\nP%d REACTION PAUSED | %.1fs" % [
			reacting_player,
			reaction_remaining
		]

	turn_label.text = display_text
