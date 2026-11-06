extends Enemy

const GRAVITY := 900.0
const ATTACK_COOLDOWN := 0.8

var _attack_timer := 0.0

@onready var melee_range: Area2D = $MeleeRange

func _move(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if _melee_target() != null:
		velocity.x = 0.0
	else:
		velocity.x = signf(_shrine_x() - global_position.x) * speed

func _attack(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	if _attack_timer > 0.0:
		return
	var target := _melee_target()
	if target == null:
		return
	target.take_damage(attack_damage)
	_attack_timer = ATTACK_COOLDOWN

func _melee_target() -> Node2D:
	for body in melee_range.get_overlapping_bodies():
		if body.has_method("take_damage"):
			return body
	return null
