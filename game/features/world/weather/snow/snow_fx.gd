extends GPUParticles3D

@export var follow_target_path: NodePath
@export var follow_camera_fallback: bool = true
@export var height_offset: float = 4.0
@export var base_amount: int = 300
@export var max_amount: int = 900
@export var min_velocity: float = 2.0
@export var max_velocity: float = 8.0
@export var max_spread_deg: float = 35.0

var _pmat: ParticleProcessMaterial
var _restart_cooldown: float = 0.0

const AMOUNT_CHANGE_THRESHOLD: int = 10
const RESTART_COOLDOWN_SEC: float = 0.5


func _ready() -> void:
	if process_material:
		_pmat = process_material.duplicate()
		process_material = _pmat
	if emitting == false:
		emitting = true


func _process(delta: float) -> void:
	if _restart_cooldown > 0.0:
		_restart_cooldown -= delta
	var target := _get_target()
	if target:
		var pos := target.global_transform.origin
		pos.y += height_offset
		global_transform.origin = pos


func set_active(active: bool) -> void:
	emitting = active


func set_wind(dir: Vector3, speed: float, is_blizzard: bool) -> void:
	if _pmat == null:
		return
	var ndir := dir
	if ndir.length() < 0.001:
		ndir = Vector3(0.0, -1.0, 0.0)
	ndir = ndir.normalized()

	var speed01: float = clamp(speed / 32.0, 0.0, 1.0)
	var vel_min: float = lerp(min_velocity, max_velocity * 0.8, speed01)
	var vel_max: float = lerp(max_velocity * 0.6, max_velocity, speed01)
	_pmat.direction = ndir
	_pmat.gravity = Vector3(0.0, -3.0, 0.0)
	_pmat.initial_velocity_min = vel_min
	_pmat.initial_velocity_max = vel_max

	var spread: float = lerp(10.0, max_spread_deg, speed01)
	_pmat.angle_min = -spread
	_pmat.angle_max = spread

	var base_target: float = lerp(float(base_amount), float(max_amount), speed01)
	var multiplier: float = _blizzard_amount_multiplier(speed) if is_blizzard else 1.0
	var new_amount: int = int(round(base_target * multiplier))
	var diff := abs(new_amount - amount)
	if diff >= AMOUNT_CHANGE_THRESHOLD or amount == 0:
		amount = new_amount
		if emitting and _restart_cooldown <= 0.0:
			restart()
			_restart_cooldown = RESTART_COOLDOWN_SEC


func _get_target() -> Node3D:
	if follow_target_path != NodePath() and has_node(follow_target_path):
		var n := get_node(follow_target_path)
		if n is Node3D:
			return n
	if follow_camera_fallback:
		return get_viewport().get_camera_3d()
	return null


func _blizzard_amount_multiplier(speed: float) -> float:
	if speed >= 32.0:
		return 5.0
	if speed >= 30.0:
		var t30 := clamp((speed - 30.0) / 2.0, 0.0, 1.0)
		return lerp(4.0, 5.0, t30)
	if speed >= 25.0:
		var t25 := clamp((speed - 25.0) / 5.0, 0.0, 1.0)
		return lerp(3.0, 4.0, t25)
	if speed >= 20.0:
		return 3.0
	if speed >= 12.0:
		var t12 := clamp((speed - 12.0) / 8.0, 0.0, 1.0)
		return lerp(2.0, 3.0, t12)
	return 1.0
