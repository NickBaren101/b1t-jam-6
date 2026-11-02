class_name Enemy
extends CharacterBody2D

enum Target { SHRINE, PLAYER }

const CONTACT_COOLDOWN := 0.8
const DESPAWN_DISTANCE := 260.0
const TARGET_DEADZONE := 2.0

@export var target := Target.SHRINE
@export var speed := 40.0
@export var contact_damage := 1
@export var favour_reward := 1

var _contact_timer := 0.0

@onready var health: HealthComponent = $HealthComponent
@onready var contact_hitbox: Area2D = $ContactHitbox

func _ready() -> void:
	health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	_move(delta)
	move_and_slide()
	_process_contact(delta)
	_check_despawn()

func _move(_delta: float) -> void:
	pass

func _approach_dir() -> float:
	var group := &"player" if target == Target.PLAYER else &"shrine"
	var node := get_tree().get_first_node_in_group(group) as Node2D
	var target_x := Tiers.CENTER_X if node == null else node.global_position.x
	var delta_x := target_x - global_position.x
	return 0.0 if absf(delta_x) < TARGET_DEADZONE else signf(delta_x)

func _process_contact(delta: float) -> void:
	_contact_timer = maxf(_contact_timer - delta, 0.0)
	if _contact_timer > 0.0:
		return
	for body in contact_hitbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)
			_contact_timer = CONTACT_COOLDOWN
			return

func _check_despawn() -> void:
	if absf(global_position.x - Tiers.CENTER_X) > DESPAWN_DISTANCE:
		queue_free()

func take_damage(amount: int) -> void:
	health.take_damage(amount)

func _on_died() -> void:
	Favour.add(favour_reward)
	queue_free()
