class_name Flyer
extends Enemy

const STOP_OFFSET := 20.0        # 160 - 20 = 140 (left), 160 + 20 = 180 (right)
const QUEUE_GAP := 10.0          # extra px between queued flyers
const MAX_QUEUE := 5             # max flyers per side and lane (see spawner)
const ARRIVE_EPSILON := 0.5
const FIRST_SHOT_DELAY := 0.6    # pause after arriving before the first shot
const SHOOT_INTERVAL := 1.8

const TELEGRAPH_TIME := 0.5
const AIM_LINE_LENGTH := 200.0
const TELEGRAPH_COLOR := Color(1.0, 0.3, 0.3)

var _telegraphing := false
var _aim_dir := Vector2.ZERO
var _aim_line: Line2D

@export var lane := 0
@export var projectile_scene: PackedScene
@export var width_override := 0.0  # 0 = measure from CollisionShape2D

# Key: Vector2i(side, lane), side 0 = left, 1 = right. Value: Array of Flyers, front first.
static var _queues: Dictionary = {}

var in_position := false
var _side := 0
var _width := 16.0
var _registered := false
var _shoot_timer := 0.0


static func queue_size(side: int, flyer_lane: int) -> int:
	return (_queues.get(Vector2i(side, flyer_lane), []) as Array).size()


static func is_queue_full(side: int, flyer_lane: int) -> bool:
	return queue_size(side, flyer_lane) >= MAX_QUEUE


static func reset_queues() -> void:
	_queues.clear()


func _ready() -> void:
	super._ready()
	_width = _measure_width()
	_create_aim_line()


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

	if in_position:
		_update_shooting(delta)


# Flyers deal no contact damage (they only hurt via projectiles)
func _process_contact(_delta: float) -> void:
	pass


func _on_died() -> void:
	_cancel_telegraph()
	_leave_queue()  # the ones behind start advancing immediately
	super._on_died()


# ---------- Queue ----------

func _register() -> void:
	# Position is set after add_child(), so the side can only be read now
	_side = 0 if global_position.x < Tiers.CENTER_X else 1
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

	var offset := STOP_OFFSET
	for i in range(1, index + 1):
		var ahead: Flyer = queue[i - 1]
		var current: Flyer = queue[i]
		offset += (ahead._width + current._width) * 0.5 + QUEUE_GAP

	var dir := -1.0 if _side == 0 else 1.0
	return Tiers.CENTER_X + dir * offset


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
	_aim_dir = (player.global_position - global_position).normalized()
	_aim_line.points = PackedVector2Array([
		global_position,
		global_position + _aim_dir * AIM_LINE_LENGTH,
	])
	_aim_line.visible = true
	_telegraphing = true
	_shoot_timer = TELEGRAPH_TIME
	_animate_telegraph()


func _animate_telegraph() -> void:
	var progress := 1.0 - clampf(_shoot_timer / TELEGRAPH_TIME, 0.0, 1.0)
	modulate = Color.WHITE.lerp(TELEGRAPH_COLOR, progress)
	_aim_line.default_color = Color(
		TELEGRAPH_COLOR.r, TELEGRAPH_COLOR.g, TELEGRAPH_COLOR.b,
		lerpf(0.2, 1.0, progress)
	)


func _end_telegraph() -> void:
	_telegraphing = false
	_aim_line.visible = false
	modulate = Color.WHITE


# Called when the flyer has to move again: no shot, start over after stopping
func _cancel_telegraph() -> void:
	if _telegraphing:
		_end_telegraph()


func _shoot() -> void:
	var proj: EnemyProjectile = projectile_scene.instantiate()
	proj.direction = _aim_dir
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position


func _create_aim_line() -> void:
	_aim_line = Line2D.new()
	_aim_line.top_level = true  # points are in global coordinates
	_aim_line.width = 1.5
	_aim_line.default_color = TELEGRAPH_COLOR
	_aim_line.visible = false
	add_child(_aim_line)

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


func _on_contact_hitbox_body_entered(_body: Node2D) -> void:
	pass  # kept so the existing signal connection in flyer.tscn doesn't break
