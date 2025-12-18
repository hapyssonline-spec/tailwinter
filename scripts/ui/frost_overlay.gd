extends CanvasLayer

@export var player_path: NodePath
@export var overlay_path: NodePath = NodePath("FrostOverlay")
@export var appear_warmth: float = 40.0
@export var full_warmth: float = 10.0
@export var smooth_speed: float = 3.5
@export var max_alpha: float = 0.6
@export var run_speed: float = 6.0

var _player: Node
var _overlay: TextureRect
var _alpha: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	_overlay = get_node_or_null(overlay_path) as TextureRect
	_player = _resolve_player()
	if _overlay:
		_overlay.modulate.a = 0.0


func _process(delta: float) -> void:
	if _overlay == null:
		return
	if _player == null or not is_instance_valid(_player):
		_player = _resolve_player()
		if _player == null:
			return

	_time += delta
	var warmth: float = _get_warmth()
	var activity01: float = _get_activity01()

	var target: float = 0.0
	if warmth < appear_warmth:
		var t: float = float(inverse_lerp(appear_warmth, full_warmth, warmth))
		target = float(clamp(t, 0.0, 1.0))

	target *= float(clamp(1.0 + 0.2 * activity01, 0.0, 1.2))

	var k: float = 1.0 - exp(-delta * smooth_speed)
	_alpha = lerp(_alpha, target, k)

	var cold01: float = 1.0 - float(clamp(warmth / 100.0, 0.0, 1.0))
	var pulse: float = sin(_time * 0.7) * 0.02 * cold01
	var final_alpha: float = float(clamp((_alpha + pulse) * max_alpha, 0.0, max_alpha))
	_overlay.modulate.a = final_alpha


func _resolve_player() -> Node:
	if player_path != NodePath("") and has_node(player_path):
		return get_node(player_path)
	return get_tree().get_first_node_in_group("player")


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
