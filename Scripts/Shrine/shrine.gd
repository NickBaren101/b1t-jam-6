class_name Shrine
extends StaticBody2D

const CLIMB_HALF_WIDTH := 8.0
const CLIMB_TOP_SLACK := 2.0

# Rows in Temple.png coordinates (Temple is placed in them; Only_Temple.png sits at (96, 28)).
# The shrine origin sits on the ground, so image row 174 (the ground line) maps to y = 0.
const GROUND_ROW := 174.0
const IMAGE_TOP_Y := -GROUND_ROW
const UPPER_EAVE_ROW := 80.0
const LOWER_EAVE_ROW := 126.0
# Temple y offset per stage: roof only -> upper eave at tier 1 height -> full temple
const STAGE_OFFSET: Array[float] = [GROUND_ROW - UPPER_EAVE_ROW, LOWER_EAVE_ROW - UPPER_EAVE_ROW, 0.0]
const RISE_TIME := 3.0

var stage := 0

@onready var health: HealthComponent = $HealthComponent
# The temple is the platform body: it must be moved itself (not a parent) so
# AnimatableBody2D syncs to physics and carries a player standing on it
@onready var temple: AnimatableBody2D = $Temple
# Revealed in this order: stage 1 unlocks the upper eave, stage 2 the lower one
@onready var _eave_shapes: Array[CollisionShape2D] = [
	$Temple/UpperEave as CollisionShape2D,
	$Temple/LowerEave as CollisionShape2D,
]

func _ready() -> void:
	temple.position.y = IMAGE_TOP_Y + STAGE_OFFSET[0]

func climb_rect() -> Rect2:
	var left := global_position.x - CLIMB_HALF_WIDTH
	var width := CLIMB_HALF_WIDTH * 2.0
	if stage == 0:
		return Rect2(left, Tiers.GROUND_SURFACE_Y, width, 0.0)
	var top := climb_top_y() - CLIMB_TOP_SLACK
	return Rect2(left, top, width, Tiers.GROUND_SURFACE_Y - top)

func climb_top_y() -> float:
	if stage == 0:
		return Tiers.stand_center_y(Tiers.GROUND_SURFACE_Y, Tiers.PLAYER_HALF_H)
	return Tiers.stand_center_y(Tiers.SURFACE_Y[stage - 1], Tiers.PLAYER_HALF_H)

# Raises the temple to the next stage, then makes the newly revealed eave solid.
# Await it: returns once the rise is done.
func rise() -> void:
	if stage >= STAGE_OFFSET.size() - 1:
		return
	stage += 1
	Sfx.play(&"upgrade")
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(temple, ^"position:y", IMAGE_TOP_Y + STAGE_OFFSET[stage], RISE_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	_eave_shapes[stage - 1].set_deferred(&"disabled", false)

# Jumps straight to a stage, no rise animation (used to skip the waves when testing)
func set_stage(value: int) -> void:
	stage = value
	temple.position.y = IMAGE_TOP_Y + STAGE_OFFSET[stage]
	for i in _eave_shapes.size():
		_eave_shapes[i].disabled = i >= stage

func take_damage(amount: int) -> void:
	health.take_damage(amount)
