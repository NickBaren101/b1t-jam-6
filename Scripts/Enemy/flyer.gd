extends Enemy

const STOP_FRACTION := 0.7
const SPACING := 14.0
const FIRE_INTERVAL := 1.6
const FIRST_SHOT_DELAY := 0.5
const CONTACT_COOLDOWN := 0.8

@export var lane := 0
@export var projectile_scene: PackedScene

var _stop_dist := -1.0
var _fire_timer := FIRST_SHOT_DELAY
var _contact_timer := 0.0

@onready var contact_hitbox: Area2D = $ContactHitbox

func _move(_delta: float) -> void:
	var offset := _shrine_x() - global_position.x
	if _stop_dist < 0.0:
		_stop_dist = absf(offset) * (1.0 - STOP_FRACTION)
	var dir := signf(offset)
	if absf(offset) <= _stop_dist or _blocked_by_flyer_ahead(dir):
		dir = 0.0
	velocity = Vector2(dir * speed, 0.0)

func _blocked_by_flyer_ahead(dir: float) -> bool:
	for other in get_tree().get_nodes_in_group(&"flyers"):
		if other == self or other.lane != lane:
			continue
		var ahead: float = (other.global_position.x - global_position.x) * dir
		if ahead > 0.0 and ahead < SPACING:
			return true
	return false

func _attack(delta: float) -> void:
	_process_contact(delta)
	if velocity.x != 0.0:
		return
	_fire_timer -= delta
	if _fire_timer > 0.0:
		return
	_fire_timer = FIRE_INTERVAL
	_fire()

func _process_contact(delta: float) -> void:
	_contact_timer = maxf(_contact_timer - delta, 0.0)
	if _contact_timer > 0.0:
		return
	for body in contact_hitbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)
			_contact_timer = CONTACT_COOLDOWN
			return

func _fire() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null or projectile_scene == null:
		return
	var projectile := projectile_scene.instantiate()
	projectile.direction = global_position.direction_to(player.global_position)
	projectile.damage = attack_damage
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
