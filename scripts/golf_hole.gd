
class_name GolfHole
extends Node2D

@export var cup_radius: float = 9.0
@export var cup_color: Color = Color("#192d20")

@export var flag_height: float = 30.0
@export var flag_color: Color = Color("#ff6b6b")


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Draw the cup.
	draw_circle(
		Vector2.ZERO,
		cup_radius,
		cup_color
	)

	# Draw the flagpole.
	draw_line(
		Vector2.ZERO,
		Vector2(0, -flag_height),
		Color.WHITE,
		2.0
	)

	# Draw the triangular flag.
	var flag_points := PackedVector2Array([
		Vector2(0, -flag_height),
		Vector2(18, -flag_height + 6),
		Vector2(0, -flag_height + 12)
	])

	draw_colored_polygon(flag_points, flag_color)
