extends CharacterBody3D

@export var move_speed: float = 1.5
@export var wander_radius: float = 20.0
@export var min_pause: float = 1.0
@export var max_pause: float = 2.5
@export var texture_path: String = "res://assets/3d/models/characters/rabbit/texture.jpg"

var _spawn_origin: Vector3
var _target_pos: Vector3
var _pause_timer: float = 0.0
var _turn_speed: float = 6.0
var _dead: bool = false

var _anim_player: AnimationPlayer
var _anim_idle: StringName
var _anim_move: StringName
var _anim_die: StringName

@onready var _interact_area: Area3D = $InteractArea
@onready var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_spawn_origin = global_position
	add_to_group("rabbits")
	_apply_texture()
	_setup_animations()
	_set_new_target()

	if _interact_area:
		_interact_area.monitoring = false
		_interact_area.monitorable = false
		_interact_area.body_entered.connect(_on_interact_body_entered)
		_interact_area.body_exited.connect(_on_interact_body_exited)


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if _pause_timer > 0.0:
		_pause_timer -= delta
		velocity = Vector3.ZERO
		_play_idle()
		move_and_slide()
		return

	var to_target := _target_pos - global_position
	to_target.y = 0.0

	if to_target.length() < 0.5:
		_pause_timer = _rng.randf_range(min_pause, max_pause)
		_set_new_target()
		_play_idle()
		return

	var dir := to_target.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	velocity.y = 0.0

	if dir.length() > 0.001:
		var target_rot := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, _turn_speed * delta)

	_play_move()
	move_and_slide()


func _set_new_target() -> void:
	var angle := _rng.randf_range(0.0, TAU)
	var dist := _rng.randf_range(2.0, wander_radius)
	var offset := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	_target_pos = _spawn_origin + offset


func _apply_texture() -> void:
	if texture_path.is_empty():
		return
	var tex: Texture2D = load(texture_path)
	if tex == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.7

	for mesh in _find_mesh_instances(self):
		var surf_count: int = mesh.mesh.get_surface_count()
		for i in range(surf_count):
			mesh.set_surface_override_material(i, mat)


func _find_mesh_instances(node: Node) -> Array:
	var result: Array = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_mesh_instances(child))
	return result


func _setup_animations() -> void:
	_anim_player = _find_anim_player(self)
	if _anim_player == null:
		return
	var names := _anim_player.get_animation_list()
	var lower: Array = []
	for n in names:
		lower.append(String(n).to_lower())

	_anim_idle = _pick_anim(names, lower, ["idle", "rest"])
	_anim_move = _pick_anim(names, lower, ["run", "walk", "move"])
	_anim_die = _pick_anim(names, lower, ["die", "death"])

	if _anim_idle == StringName():
		if names.is_empty():
			_anim_idle = StringName()
		else:
			_anim_idle = names[0]
	if _anim_move == StringName():
		_anim_move = _anim_idle


func _pick_anim(names: Array, lower: Array, keywords: Array) -> StringName:
	for k in keywords:
		for idx in range(lower.size()):
			if lower[idx].find(k) != -1:
				return names[idx]
	return StringName()


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_anim_player(child)
		if found:
			return found
	return null


func _play_idle() -> void:
	if _anim_player and _anim_idle != StringName():
		if _anim_player.current_animation != _anim_idle:
			_anim_player.play(_anim_idle)


func _play_move() -> void:
	if _anim_player and _anim_move != StringName():
		if _anim_player.current_animation != _anim_move:
			_anim_player.play(_anim_move)


func on_trapped() -> void:
	_dead = true
	_play_die()
	velocity = Vector3.ZERO
	if _interact_area:
		_interact_area.monitoring = true
		_interact_area.monitorable = true
		call_deferred("_register_overlapping_bodies")


func _play_die() -> void:
	if _anim_player == null:
		return
	if _anim_die != StringName():
		_anim_player.play(_anim_die)
	else:
		_play_idle()


func on_interact(player: Node) -> bool:
	if not _dead:
		return false
	if player == null or not ("inventory" in player):
		return false

	var weight: float = _rng.randf_range(1.5, 3.5)
	var ok: bool = false
	if player.inventory.has_method("add_item"):
		ok = player.inventory.add_item("rabbit_carcass", weight)

	if ok:
		if player.has_method("_notify_hud"):
			player.call("_notify_hud", "Тушка кролика +%.2f кг" % weight)
		_queue_remove(player)
	else:
		if player.has_method("_notify_hud"):
			player.call("_notify_hud", "Не удалось поднять тушку: инвентарь переполнен")
	return ok


func _on_interact_body_entered(body: Node) -> void:
	if not _dead:
		return
	if body.name == "Player" and body.has_method("register_interactable"):
		body.register_interactable(self)


func _on_interact_body_exited(body: Node) -> void:
	if not _dead:
		return
	if body.name == "Player" and body.has_method("unregister_interactable"):
		body.unregister_interactable(self)


func _queue_remove(player: Node) -> void:
	if player and player.has_method("unregister_interactable"):
		player.unregister_interactable(self)
	queue_free()


func _register_overlapping_bodies() -> void:
	if _interact_area == null:
		return
	for body in _interact_area.get_overlapping_bodies():
		if body.name == "Player" and body.has_method("register_interactable"):
			body.register_interactable(self)


func get_display_name() -> String:
	return "Тушка кролика" if _dead else ""
