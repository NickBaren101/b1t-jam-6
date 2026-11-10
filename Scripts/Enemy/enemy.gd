class_name Enemy
extends CharacterBody2D

const DESPAWN_DISTANCE := 260.0
const ATTACK_AREA_MARGIN := 2.0  # px the attack area reaches past the body on each side

@export var speed := 40.0
@export var attack_damage := 1
@export var favour_reward := 1
@export var attack_area: Area2D  # resized with the body when the picked look has a hitbox

@onready var health: HealthComponent = $HealthComponent
# Optional: one child is picked at random as the look, all drawn facing right.
# A look can carry metadata "hitbox" (Rect2, body space) that the collision is fitted to.
@onready var visuals: Node2D = get_node_or_null(^"Visuals")

var _sprite: AnimatedSprite2D

func _ready() -> void:
	health.died.connect(_on_died)
	_pick_visual()

func _physics_process(delta: float) -> void:
	_move(delta)
	move_and_slide()
	_update_facing()
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
	Sfx.play(&"enemy_hit")

func _on_died() -> void:
	Favour.add(favour_reward)
	queue_free()

# ---------- Visuals ----------

func _pick_visual() -> void:
	if visuals == null or visuals.get_child_count() == 0:
		return
	_sprite = visuals.get_child(randi() % visuals.get_child_count())
	for child in visuals.get_children():
		child.visible = child == _sprite
	_sprite.play(&"default")
	if _sprite.has_meta(&"hitbox"):
		_fit_hitbox(_sprite.get_meta(&"hitbox"))

func _fit_hitbox(rect: Rect2) -> void:
	_set_box($CollisionShape2D, rect)
	if attack_area != null:
		_set_box(attack_area.get_node(^"CollisionShape2D"), rect.grow(ATTACK_AREA_MARGIN))

# New shape per instance: the scene's shape resource is shared by every enemy
func _set_box(cs: CollisionShape2D, rect: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	cs.position = rect.get_center()

# Keeps the last direction while standing still
func _update_facing() -> void:
	if visuals != null and velocity.x != 0.0:
		visuals.scale.x = signf(velocity.x)

# Plays anim only if the picked variant has it
func _play_visual(anim: StringName) -> void:
	if _sprite != null and _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)
