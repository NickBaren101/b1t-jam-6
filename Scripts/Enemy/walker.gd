extends Enemy

const GRAVITY := 900.0

func _move(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = _approach_dir() * speed
