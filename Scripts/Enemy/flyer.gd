class_name Flyer
extends Enemy

const STOP_FRACTION := 0.6       # front of the queue stops 60% of the way to the shrine
const QUEUE_GAP := 10.0          # extra px between queued flyers
const MAX_QUEUE := 5             # max flyers per side and lane (see spawner)
const ARRIVE_EPSILON := 0.5
const FIRST_SHOT_DELAY := 0.6    # pause after arriving before the first shot
const SHOOT_INTERVAL := 1.8
const CONTACT_COOLDOWN := 0.8

const TELEGRAPH_TIME := 0.5
const AIM_RAY_LENGTH := 200.0
const TELEGRAPH_COLOR := Color(1.0, 0.3, 0.3)

@export var lane := 0
@export var projectile_scene: PackedScene
@export var width_override := 0.0  # 0 = measure from CollisionShape2D

# Key: Vector2i(side, lane), side 0 = left, 1 = right. Value: Array of Flyers, front first.
static var _queues: Dictionary = {}

var in_position := false
var _side := 0
var _stop_dist := 0.0
var _width := 16.0
var _registered := false
var _shoot_timer := 0.0
var _contact_timer := 0.0
var _telegraphing := false
var _aim_dir := Vector2.ZERO

@onready var contact_hitbox: Area2D = $ContactHitbox
# Only drawn with Debug > Visible Collision Shapes on
@onready var aim_ray: RayCast2D = $AimRay


static func queue_size(side: int, flyer_lane: int) -> int:
	return (_queues.get(Vector2i(side, flyer_lane), []) as Array).size()


static func is_queue_full(side: int, flyer_lane: int) -> bool:
	return queue_size(side, flyer_lane) >= MAX_QUEUE


static func reset_queues() -> void:
	_queues.clear()


func _ready() -> void:
	super._ready()
	_width = _measure_width()


func _exit_tree() -> void:
	_leave_queue()


func _move(delta: float) -> void:
	if not _registered:
		_register()

	var dx := _get_target_x() - global_position.x
	if absf(dx) <= ARRIVE_EPSILON:
		velocity = Vector2.ZERO
		if not in_position:
			in_position = true
			_shoot_timer = FIRST_SHOT_DELAY
	else:
		in_position = false
		_cancel_telegraph()
		velocity = Vector2(clampf(dx / delta, -speed, speed), 0.0)


func _attack(delta: float) -> void:
	_process_contact(delta)
	if in_position:
		_update_shooting(delta)


func _on_died() -> void:
	_cancel_telegraph()
	_leave_queue()  # the ones behind start advancing immediately
	super._on_died()


# ---------- Contact (player only, see ContactHitbox mask) ----------

func _process_contact(delta: float) -> void:
	_contact_timer = maxf(_contact_timer - delta, 0.0)
	if _contact_timer > 0.0:
		return
	for body in contact_hitbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)
			_contact_timer = CONTACT_COOLDOWN
			return


# ---------- Queue ----------

func _register() -> void:
	# Position is set after add_child(), so the side and distance can only be read now
	_side = 0 if global_position.x < Tiers.CENTER_X else 1
	_stop_dist = absf(_shrine_x() - global_position.x) * (1.0 - STOP_FRACTION)
	var key := Vector2i(_side, lane)
	if not _queues.has(key):
		_queues[key] = []
	(_queues[key] as Array).append(self)
	_registered = true


func _leave_queue() -> void:
	if not _registered:
		return
	var key := Vector2i(_side, lane)
	if _queues.has(key):
		(_queues[key] as Array).erase(self)
	_registered = false


func _get_target_x() -> float:
	var queue: Array = _queues[Vector2i(_side, lane)]
	var index := queue.find(self)
	if index == -1:
		return global_position.x

	var offset: float = (queue[0] as Flyer)._stop_dist  # whole queue anchors to the front flyer
	for i in range(1, index + 1):
		var ahead: Flyer = queue[i - 1]
		var current: Flyer = queue[i]
		offset += (ahead._width + current._width) * 0.5 + QUEUE_GAP

	var dir := -1.0 if _side == 0 else 1.0
	return _shrine_x() + dir * offset


# ---------- Shooting (only while standing still) ----------

func _update_shooting(delta: float) -> void:
	_shoot_timer -= delta

	if _shoot_timer > 0.0:
		if _telegraphing:
			_animate_telegraph()
		return

	if _telegraphing:
		_end_telegraph()
		_shoot()
		_shoot_timer = SHOOT_INTERVAL
	else:
		_begin_telegraph()


func _begin_telegraph() -> void:
	if projectile_scene == null:
		return
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return

	# Aim is locked here: the shot goes where the player WAS at this moment
	_aim_dir = global_position.direction_to(player.global_position)
	aim_ray.target_position = _aim_dir * AIM_RAY_LENGTH
	aim_ray.enabled = true
	aim_ray.visible = true
	_telegraphing = true
	_shoot_timer = TELEGRAPH_TIME
	_animate_telegraph()


func _animate_telegraph() -> void:
	var progress := 1.0 - clampf(_shoot_timer / TELEGRAPH_TIME, 0.0, 1.0)
	modulate = Color.WHITE.lerp(TELEGRAPH_COLOR, progress)


func _end_telegraph() -> void:
	_telegraphing = false
	aim_ray.enabled = false
	aim_ray.visible = false
	modulate = Color.WHITE


# Called when the flyer has to move again: no shot, start over after stopping
func _cancel_telegraph() -> void:
	if _telegraphing:
		_end_telegraph()


func _shoot() -> void:
	var proj: EnemyProjectile = projectile_scene.instantiate()
	proj.direction = _aim_dir
	proj.damage = attack_damage
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position


# ---------- Width ----------

func _measure_width() -> float:
	if width_override > 0.0:
		return width_override
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs and cs.shape:
		var sx := absf(cs.global_scale.x)
		if cs.shape is RectangleShape2D:
			return (cs.shape as RectangleShape2D).size.x * sx
		if cs.shape is CircleShape2D:
			return (cs.shape as CircleShape2D).radius * 2.0 * sx
		if cs.shape is CapsuleShape2D:
			return (cs.shape as CapsuleShape2D).radius * 2.0 * sx
	return 16.0
