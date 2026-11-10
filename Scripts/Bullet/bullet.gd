extends Area2D

signal hit_enemy

const SPEED := 220.0
const LIFETIME := 1.0

var direction := Vector2.RIGHT
var damage := 1

var _time := 0.0
var _done := false

@onready var sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.animation_finished.connect(queue_free)  # only the non-looping fade finishes
	if direction.x < 0.0:
		sprite.scale.x = -1.0
	sprite.play(&"fly")

func _physics_process(delta: float) -> void:
	if _done:
		return
	position += direction * SPEED * delta
	_time += delta
	if _time >= LIFETIME:
		_finish()

func _on_body_entered(body: Node2D) -> void:
	if _done:
		return
	if body.has_method("take_damage"):
		var is_enemy := body is Enemy
		body.take_damage(damage)
		if is_enemy:
			hit_enemy.emit()
	_finish()

# Stops in place and plays the fade, frees itself when it ends
func _finish() -> void:
	_done = true
	set_deferred(&"monitoring", false)
	sprite.play(&"fade")
