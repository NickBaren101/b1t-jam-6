class_name EnemyProjectile
extends Area2D

@export var speed := 120.0
@export var lifetime := 3.0
@export var damage := 1
@export var draw_placeholder := true  # turn off once a sprite exists

var direction := Vector2.LEFT


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	# Straight line along the locked direction, never changes
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()  # mask is World + Player, so this also covers hitting the ground


func _draw() -> void:
	if not draw_placeholder:
		return
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs and cs.shape is CircleShape2D:
		draw_circle(cs.position, (cs.shape as CircleShape2D).radius, Color(1.0, 0.35, 0.35))
