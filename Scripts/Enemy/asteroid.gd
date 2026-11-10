class_name Asteroid
extends EnemyProjectile

# Emitted where it hits the ground, the Moon's spawner turns this into walkers
signal landed(x: float)

const ROCK_COLOR := Color(0.55, 0.47, 0.4)


func _ready() -> void:
	super._ready()
	area_entered.connect(_on_area_entered)  # mask includes Bullets


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		if body.has_method("knock_down"):
			body.call_deferred(&"knock_down", damage)  # changes collision masks, not allowed mid-callback
	else:
		landed.emit(global_position.x)  # mask is World + Player, so this is the ground
	queue_free()


# Player bullets are destroyed, the asteroid keeps going
func _on_area_entered(area: Area2D) -> void:
	area.queue_free()


func _draw() -> void:
	if not draw_placeholder:
		return
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs and cs.shape is CircleShape2D:
		draw_circle(cs.position, (cs.shape as CircleShape2D).radius, ROCK_COLOR)
