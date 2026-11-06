class_name Enemy
extends CharacterBody2D

const DESPAWN_DISTANCE := 260.0

@export var speed := 40.0
@export var attack_damage := 1
@export var favour_reward := 1

@onready var health: HealthComponent = $HealthComponent

func _ready() -> void:
	health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	_move(delta)
	move_and_slide()
	_attack(delta)
	_check_despawn()

func _move(_delta: float) -> void:
	pass

func _attack(_delta: float) -> void:
	pass

func _shrine_x() -> float:
	var shrine := get_tree().get_first_node_in_group(&"shrine") as Node2D
	return Tiers.CENTER_X if shrine == null else shrine.global_position.x

func _check_despawn() -> void:
	if absf(global_position.x - Tiers.CENTER_X) > DESPAWN_DISTANCE:
		queue_free()

func take_damage(amount: int) -> void:
	health.take_damage(amount)

func _on_died() -> void:
	Favour.add(favour_reward)
	queue_free()
