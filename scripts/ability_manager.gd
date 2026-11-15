
class_name AbilityManager
extends Node

signal ability_played(player_id: int, ability_id: String)

# Maximum number of cards a player can hold.
@export_range(1, 20, 1)
var max_hand_size: int = 5

@onready var turn_manager: TurnManager = $"../TurnManager"
@onready var reaction_manager: ReactionManager = $"../ReactionManager"

# Each player has their own hand of cards.
var hands: Array = [[], []]


func _ready() -> void:
	turn_manager.turn_started.connect(_on_turn_started)
	_reset_test_hands()

	print("[ABILITY] Test hands initialized")


func _make_ability(
	id: String,
	display_name: String,
	timing: GolfAbility.Timing,
	price: int,
	flight_allowed: bool = true,
	post_allowed: bool = true
) -> GolfAbility:
	var ability := GolfAbility.new()

	ability.ability_id = id
	ability.ability_name = display_name
	ability.timing = timing
	ability.purchase_price = price
	ability.allow_in_flight = flight_allowed
	ability.allow_post_shot = post_allowed

	return ability


func _reset_test_hands() -> void:
	for player_index in range(2):
		hands[player_index] = []

		_add_card(
			player_index,
			_make_ability(
				"freeze_green",
				"Freeze Green",
				GolfAbility.Timing.PRE_SHOT,
				4
			)
		)

		_add_card(
			player_index,
			_make_ability(
				"repair_club",
				"Repair Club",
				GolfAbility.Timing.POST_SHOT,
				3
			)
		)

		_add_card(
			player_index,
			_make_ability(
				"sudden_gust",
				"Sudden Gust",
				GolfAbility.Timing.INSTANT,
				9
			)
		)

		_add_card(
			player_index,
			_make_ability(
				"sudden_gust",
				"Sudden Gust",
				GolfAbility.Timing.INSTANT,
				9
			)
		)


func _add_card(
	player_index: int,
	ability: GolfAbility
) -> bool:
	if hands[player_index].size() >= max_hand_size:
		print(
			"[REJECTED] Player ",
			player_index + 1,
			" has reached maximum hand size"
		)
		return false

	hands[player_index].append(ability)
	return true


func _on_turn_started(
	_player_index: int,
	turn_number: int
) -> void:
	# Temporary testing behaviour:
	# Refill both hands at the start of every turn.
	_reset_test_hands()

	print(
		"[ABILITY] Test hands reset for turn ",
		turn_number
	)


func _is_timing_legal(
	ability: GolfAbility,
	player_index: int
) -> bool:
	var phase: TurnManager.Phase = turn_manager.phase

	match ability.timing:
		GolfAbility.Timing.PRE_SHOT:
			return (
				phase == TurnManager.Phase.PRE_SHOT
				and player_index == turn_manager.current_player
				and not reaction_manager.is_reaction_open
			)

		GolfAbility.Timing.POST_SHOT:
			return (
				phase == TurnManager.Phase.POST_SHOT
				and player_index == turn_manager.current_player
				and not reaction_manager.is_reaction_open
			)

		GolfAbility.Timing.INSTANT:
			if phase == TurnManager.Phase.BALL_IN_MOTION:
				return ability.allow_in_flight

			if phase == TurnManager.Phase.POST_SHOT:
				return ability.allow_post_shot

	return false


func has_playable_instant(
	player_index: int,
	phase: TurnManager.Phase
) -> bool:
	if player_index < 0 or player_index >= hands.size():
		return false

	for card in hands[player_index]:
		var ability: GolfAbility = card

		if ability.timing != GolfAbility.Timing.INSTANT:
			continue

		if (
			phase == TurnManager.Phase.BALL_IN_MOTION
			and ability.allow_in_flight
		):
			return true

		if (
			phase == TurnManager.Phase.POST_SHOT
			and ability.allow_post_shot
		):
			return true

	return false


func try_play_ability(
	player_index: int,
	ability_id: String
) -> bool:
	if player_index < 0 or player_index >= hands.size():
		return false

	for card_index in range(hands[player_index].size()):
		var ability: GolfAbility = hands[player_index][card_index]

		if ability.ability_id != ability_id:
			continue

		if not _is_timing_legal(ability, player_index):
			print(
				"[REJECTED] ",
				ability.ability_name,
				" cannot be played in the current phase"
			)
			return false

		# Instants require an owned, open reaction window.
		if ability.timing == GolfAbility.Timing.INSTANT:
			if (
				not reaction_manager.is_reaction_open
				or reaction_manager.reaction_player != player_index
			):
				print(
					"[REJECTED] Open your own reaction window first"
				)
				return false

		# Consume one copy of the card.
		hands[player_index].remove_at(card_index)

		print(
			"[ABILITY] Player ",
			player_index + 1,
			" played ",
			ability.ability_name,
			" | Cards remaining: ",
			hands[player_index].size()
		)

		if ability.timing == GolfAbility.Timing.INSTANT:
			reaction_manager.record_card_played(player_index)

		ability_played.emit(player_index, ability.ability_id)
		return true

	print(
		"[REJECTED] Player ",
		player_index + 1,
		" does not have card: ",
		ability_id
	)

	return false
