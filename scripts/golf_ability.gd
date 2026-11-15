
class_name GolfAbility
extends Resource

enum Timing {
	PRE_SHOT,
	POST_SHOT,
	INSTANT
}

@export var ability_id: String = ""
@export var ability_name: String = ""
@export_multiline var description: String = ""

@export var timing: Timing = Timing.PRE_SHOT

# Cost to purchase the card at the clubhouse.
# No cost is incurred when activating it.
@export_range(0, 999, 1)
var purchase_price: int = 0

# Only relevant to INSTANT abilities.
@export var allow_in_flight: bool = true
@export var allow_post_shot: bool = true
