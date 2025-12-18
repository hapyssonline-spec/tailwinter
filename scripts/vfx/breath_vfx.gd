extends Node3D

@export var player_path: NodePath
@export var particles_path: NodePath = NodePath("BreathGPUParticles")
@export var smooth_speed: float = 8.0
@export var run_speed: float = 6.0

var _player: Node
var _particles: GPUParticles3D
var _material: ParticleProcessMaterial
var _base_amount_ratio: float = 1.0
var _base_lifetime: float = 0.8
var _base_velocity: Vector2 = Vector2(0.6, 0.6)
var _intensity: float = 0.0


func _ready() -> void:
	_player = _resolve_player()
	_particles = get_node_or_null(particles_path) as GPUParticles3D
	if _particles:
		_particles.emitting = false
		_base_amount_ratio = _particles.amount_ratio
		_base_lifetime = _particles.lifetime
		_material = _particles.process_material as ParticleProcessMaterial
		if _material:
			_base_velocity = _material.initial_velocity


func _process(delta: float) -> void:
	if _particles == null:
		return
	if _player == null or not is_instance_valid(_player):
		_player = _resolve_player()
		if _player == null:
			return

	var warmth: float = _get_warmth()
	var warmth01: float = float(clamp(warmth / 100.0, 0.0, 1.0))
	var cold01: float = 1.0 - warmth01
	var activity01: float = _get_activity01()

	var target: float = 0.0
	if cold01 >= 0.15:
		target = cold01 * (0.35 + 0.65 * activity01)

	var k: float = 1.0 - exp(-delta * smooth_speed)
	_intensity = lerp(_intensity, target, k)

	var ratio: float = float(clamp(_intensity, 0.0, 1.0))
	_particles.amount_ratio = ratio * _base_amount_ratio
	_particles.emitting = ratio > 0.02

	if _material:
		var activity_boost: float = 0.6 + 0.8 * activity01
		_material.initial_velocity = _base_velocity * activity_boost
		_particles.lifetime = max(0.3, _base_lifetime * (1.0 - 0.35 * activity01))


func _resolve_player() -> Node:
	if player_path != NodePath("") and has_node(player_path):
		return get_node(player_path)
	var p: Node = get_tree().get_first_node_in_group("player")
	return p


func _get_warmth() -> float:
	if _player == null:
		return 100.0
	if "warmth" in _player:
		return float(_player.warmth)
	if _player.has_method("get_stats"):
		var stats: Variant = _player.call("get_stats")
		if stats is Dictionary and stats.has("body_temp"):
			return float(stats.get("body_temp", 100.0))
	if "stats" in _player and _player.stats:
		var s: Variant = _player.stats
		if "body_temperature" in s:
			return float(s.body_temperature)
	return 100.0


func _get_activity01() -> float:
	var speed: float = 0.0
	if "velocity" in _player:
		speed = _player.velocity.length()
	elif _player.has_method("get_velocity"):
		var v: Variant = _player.call("get_velocity")
		if v is Vector3:
			speed = v.length()

	var activity: float = float(clamp(speed / run_speed, 0.0, 1.0))

	if _player.has_method("is_sprinting") and bool(_player.call("is_sprinting")):
		activity = clamp(activity + 0.2, 0.0, 1.0)
	elif "is_sprinting" in _player and bool(_player.is_sprinting):
		activity = clamp(activity + 0.2, 0.0, 1.0)
	elif "stats" in _player and _player.stats and "stamina" in _player.stats:
		var stamina: float = float(_player.stats.stamina)
		if stamina < 40.0 and activity > 0.1:
			activity = clamp(activity + 0.1, 0.0, 1.0)

	return activity
