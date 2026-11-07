extends Area2D

signal hit_enemy

const SPEED := 220.0
const LIFETIME := 1.0

var direction := Vector2.RIGHT
var damage := 1

var _time := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	_time += delta
	if _time >= LIFETIME:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		var is_enemy := body is Enemy
		body.take_damage(damage)
		if is_enemy:
			hit_enemy.emit()
	queue_free()
