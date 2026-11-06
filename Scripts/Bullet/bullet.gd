extends Area2D

@export var speed := 220.0
@export var lifetime := 1.0

var direction := Vector2.RIGHT
var damage := 1

var _time := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_time += delta
	if _time >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
