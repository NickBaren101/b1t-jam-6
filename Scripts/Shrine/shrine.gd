class_name Shrine
extends StaticBody2D

const CLIMB_HALF_WIDTH := 8.0
const CLIMB_TOP_SLACK := 2.0

var _unlocked := 0

@onready var health: HealthComponent = $HealthComponent
@onready var _tiers: Array[Node2D] = [$Tier1 as Node2D, $Tier2 as Node2D]

func _ready() -> void:
	Favour.tier_unlocked.connect(_on_tier_unlocked)

func climb_rect() -> Rect2:
	var left := global_position.x - CLIMB_HALF_WIDTH
	var width := CLIMB_HALF_WIDTH * 2.0
	if _unlocked == 0:
		return Rect2(left, Tiers.GROUND_SURFACE_Y, width, 0.0)
	var top := climb_top_y() - CLIMB_TOP_SLACK
	return Rect2(left, top, width, Tiers.GROUND_SURFACE_Y - top)

func climb_top_y() -> float:
	if _unlocked == 0:
		return Tiers.stand_center_y(Tiers.GROUND_SURFACE_Y, Tiers.PLAYER_HALF_H)
	return Tiers.stand_center_y(Tiers.SURFACE_Y[_unlocked - 1], Tiers.PLAYER_HALF_H)

func _on_tier_unlocked(index: int) -> void:
	_unlocked = maxi(_unlocked, index + 1)
	var tier := _tiers[index]
	tier.visible = true
	tier.get_node("Body/CollisionShape2D").set_deferred("disabled", false)

func take_damage(amount: int) -> void:
	health.take_damage(amount)
