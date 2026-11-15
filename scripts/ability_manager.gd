
class_name AbilityManager
extends Node

signal ability_played(
	player_id: int,
	ability_id: String
)

@export_range(1, 20, 1)
var max_hand_size: int = 5

@onready var turn_manager: TurnManager = $"../TurnManager"
@onready var reaction_manager: ReactionManager = $"../ReactionManager"
@onready var targeting_controller: TargetingController = $"../TargetingController"

var hands: Array = [[], []]

# Track a card while the player chooses its target.
var pending_ability: GolfAbility = null
var pending_player: int = -1


func _ready() -> void:
	turn_manager.turn_started.connect(_on_turn_started)

	targeting_controller.target_selected.connect(
		_on_target_selected
	)

	targeting_controller.targeting_cancelled.connect(
		_on_targeting_cancelled
	)

	_reset_test_hands()
	print("[ABILITY] Test hands initialized")


func _make_ability(
	id: String,
	display_name: String,
	timing: GolfAbility.Timing,
	price: int,
	target: GolfAbility.TargetType
) -> GolfAbility:
	var ability := GolfAbility.new()

	ability.ability_id = id
	ability.ability_name = display_name
	ability.timing = timing
	ability.purchase_price = price
	ability.target_type = target

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
				4,
				GolfAbility.TargetType.COURSE_AREA
			)
		)

		_add_card(
			player_index,
			_make_ability(
				"repair_club",
				"Repair Club",
				GolfAbility.Timing.POST_SHOT,
				3,
				GolfAbility.TargetType.NONE
			)
		)

		for i in range(2):
			_add_card(
				player_index,
				_make_ability(
					"sudden_gust",
					"Sudden Gust",
					GolfAbility.Timing.INSTANT,
					9,
					GolfAbility.TargetType.BALL
				)
			)


func _add_card(
	player_index: int,
	ability: GolfAbility
) -> bool:
	if hands[player_index].size() >= max_hand_size:
		print("[REJECTED] Maximum hand size reached")
		return false

	hands[player_index].append(ability)
	return true


func _on_turn_started(
	_player_index: int,
	turn_number: int
) -> void:
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

		if phase == TurnManager.Phase.BALL_IN_MOTION:
			if ability.allow_in_flight:
				return true

		if phase == TurnManager.Phase.POST_SHOT:
			if ability.allow_post_shot:
				return true

	return false


func try_play_ability(
	player_index: int,
	ability_id: String
) -> bool:
	# Only one card can be awaiting a target at a time.
	if pending_ability != null:
		print("[REJECTED] Finish targeting first")
		return false

	if player_index < 0 or player_index >= hands.size():
		return false

	for card in hands[player_index]:
		var ability: GolfAbility = card

		if ability.ability_id != ability_id:
			continue

		if not _is_timing_legal(ability, player_index):
			print("[REJECTED] Invalid ability timing")
			return false

		if ability.timing == GolfAbility.Timing.INSTANT:
			if (
				not reaction_manager.is_reaction_open
				or reaction_manager.reaction_player != player_index
			):
				print("[REJECTED] Open your reaction window first")
				return false

		# Do not consume the card yet.
		pending_ability = ability
		pending_player = player_index

		print(
			"[ABILITY] Select a target for ",
			ability.ability_name
		)

		targeting_controller.begin_targeting(ability)
		return true

	print("[REJECTED] Card not found in hand")
	return false


func _on_target_selected(
	ability_id: String,
	_target_type: int,
	target_data: Dictionary
) -> void:
	if pending_ability == null:
		return

	if pending_ability.ability_id != ability_id:
		return

	var player_index: int = pending_player
	var ability: GolfAbility = pending_ability

	# Confirm the card is still in the player's hand.
	var card_index: int = hands[player_index].find(ability)

	if card_index == -1:
		print("[REJECTED] Pending card no longer available")
		_clear_pending()
		return

	# Consume the card only after targeting succeeds.
	hands[player_index].remove_at(card_index)

	print(
		"[ABILITY] Player ",
		player_index + 1,
		" played ",
		ability.ability_name,
		" | Target: ",
		target_data
	)

	_clear_pending()

	if ability.timing == GolfAbility.Timing.INSTANT:
		reaction_manager.record_card_played(player_index)

	ability_played.emit(player_index, ability.ability_id)


func _on_targeting_cancelled() -> void:
	print("[ABILITY] Targeting cancelled — card retained")
	_clear_pending()


func _clear_pending() -> void:
	pending_ability = null
	pending_player = -1
