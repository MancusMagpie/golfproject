
class_name GolfAbility
extends Resource

enum Timing {
	PRE_SHOT,
	POST_SHOT,
	INSTANT
}

enum TargetType {
	NONE,
	BALL,
	COURSE_AREA,
	GOLFER,
	GAME
}

@export var ability_id: String = ""
@export var ability_name: String = ""
@export_multiline var description: String = ""

@export var timing: Timing = Timing.PRE_SHOT

# Purchase price at the clubhouse.
# Playing a card does not cost anything.
@export_range(0, 999, 1)
var purchase_price: int = 0

# What the ability targets.
@export var target_type: TargetType = TargetType.NONE

# Only relevant to instant abilities.
@export var allow_in_flight: bool = true
@export var allow_post_shot: bool = true
