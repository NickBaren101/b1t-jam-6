extends Enemy

@export var lane := 0

func _move(_delta: float) -> void:
	velocity = Vector2(_approach_dir() * speed, 0.0)
