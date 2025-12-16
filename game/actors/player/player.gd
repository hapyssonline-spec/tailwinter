extends CharacterBody3D

const SurvivalStatsRes = preload("res://game/features/survival/stats/survival_stats.gd")
const InventoryRes = preload("res://game/features/inventory/inventory.gd")
const TrapScene: PackedScene = preload("res://game/props/trap/trap.tscn")
const TRAP_ITEM_ID := "trap"
const RABBIT_CARCASS_ID := "rabbit_carcass"
const RABBIT_MEAT_RAW_ID := "rabbit_meat_raw"
const RABBIT_MEAT_COOKED_ID := "rabbit_meat_cooked"

@export var stats: SurvivalStats = SurvivalStatsRes.new()
@export var inventory: InventoryData = InventoryRes.new()
@export var traps_in_inventory: int = 3

const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 6.0
const STAMINA_DRAIN_RATE: float = 18.0
const STAMINA_REGEN_RATE: float = 15.0
const GRAVITY: float = 30.0
const WIND_K: float = 0.35
const WIND_MIN_MUL: float = 0.65
const WIND_MAX_MUL: float = 1.35

@export var speed_forward: float = 5.0
@export var speed_backward_factor: float = 0.3  # назад на 70% медленнее
@export var speed_strafe_factor: float = 0.75   # вбок на 25% медленнее
@export var mouse_sensitivity: float = 0.1
@export var fov: float = 85.0

var yaw: float = 0.0
var pitch: float = 0.0

var _log_timer: float = 0.0
var _interactables: Array = []
@onready var _camera: Camera3D = get_node_or_null("HeadCamera")
@onready var _hands: Node3D = get_node_or_null("HeadCamera/HandsFP")
var ui_blocked: bool = false
var _wind_speed_mps: float = 0.0
var _wind_dir_xz: Vector3 = Vector3.ZERO
var _interact_hint: String = ""
var _poison_damage_left: float = 0.0
var _poison_tick_timer: float = 0.0
var _ui_hud: Node = null


func _ready() -> void:
	add_to_group("player")
	_ensure_input_actions()
	if traps_in_inventory > 0 and inventory != null:
		inventory.add(TRAP_ITEM_ID, traps_in_inventory)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if _camera:
		_camera.fov = fov
		_camera.near = 0.05
		_camera.far = 800.0


func _physics_process(delta: float) -> void:
	if ui_blocked:
		stats.update(delta)
		return

	_apply_look()
	var is_sprinting := _handle_movement(delta)

	stats.stamina_regen_rate = 0.0 if is_sprinting else STAMINA_REGEN_RATE
	stats.update(delta)

	if is_sprinting:
		stats.drain_stamina(STAMINA_DRAIN_RATE * delta)

	if stats.is_dead():
		_on_player_dead()

	_log_stats(delta)


func register_interactable(node: Node) -> void:
	if not _interactables.has(node):
		_interactables.append(node)


func unregister_interactable(node: Node) -> void:
	_interactables.erase(node)


func _handle_movement(delta: float) -> bool:
	# Движение по плоскости XZ с учётом ориентации игрока (first-person).
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")

	if input_dir.length_squared() > 1.0:
		input_dir = input_dir.normalized()

	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var z_speed := speed_forward
	if input_dir.y > 0.0:
		z_speed = speed_forward * speed_backward_factor
	var x_speed := speed_forward * speed_strafe_factor

	var move_dir := Vector3.ZERO
	if abs(input_dir.y) > 0.0:
		move_dir += forward * (-input_dir.y) * z_speed
	if abs(input_dir.x) > 0.0:
		move_dir += right * input_dir.x * x_speed

	var is_moving := move_dir != Vector3.ZERO
	var can_sprint := Input.is_action_pressed("sprint") and stats.stamina > 0.0
	if is_moving and can_sprint:
		move_dir *= (SPRINT_SPEED / WALK_SPEED)

	if is_moving:
		var horiz_dir := move_dir.normalized()
		var wind_mul := _compute_wind_multiplier(horiz_dir)
		move_dir *= wind_mul
		velocity.x = move_dir.x
		velocity.z = move_dir.z
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed_forward)
		velocity.z = move_toward(velocity.z, 0.0, speed_forward)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	if Input.is_action_just_pressed("interact"):
		var did := _try_interact()
		if did:
			_play_hands_action()
	if Input.is_action_just_pressed("place_trap"):
		var placed := _place_trap()
		if placed:
			_play_hands_action()
	_update_interact_hint()
	return is_moving and can_sprint


func _on_player_dead() -> void:
	print("Игрок погиб. (пока без рестарта и UI)")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.pressed:
			# Захватите курсор обратно при необходимости:
			# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			pass
		return

	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -80.0, 80.0)


func _try_interact() -> bool:
	if _interactables.is_empty():
		return false

	var closest: Node = null
	var closest_dist: float = INF
	for n in _interactables:
		if not is_instance_valid(n):
			continue
		var d := global_position.distance_to(n.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = n

	if closest != null and closest.is_in_group("campfire"):
		_open_campfire_ui(closest)
		return true

	if closest != null and closest.has_method("on_interact"):
		var res = closest.on_interact(self)
		if res is bool:
			return res
		return true
	return false


func _open_campfire_ui(node: Node) -> void:
	get_tree().call_group("hud", "open_campfire_menu", node)


func _log_stats(delta: float) -> void:
	_log_timer += delta

	if _log_timer >= 1.0:
		_log_timer = 0.0
		print("HP: %.1f | BodyTemp: %.1f | Hunger: %.1f | Thirst: %.1f | Stamina: %.1f" % [
			stats.health,
			stats.body_temperature,
			stats.hunger,
			stats.thirst,
			stats.stamina
		])


func _update_interact_hint() -> void:
	if _camera == null:
		return
	var forward := -_camera.global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()

	var best: Node = null
	var best_dot: float = 0.0
	var max_dist := 3.0

	for n in _interactables:
		if not is_instance_valid(n):
			continue
		var to: Vector3 = n.global_position - _camera.global_position
		var dist: float = to.length()
		if dist <= 0.01 or dist > max_dist:
			continue
		to.y = 0.0
		if to == Vector3.ZERO:
			continue
		var dir: Vector3 = to.normalized()
		var dot: float = dir.dot(forward)
		if dot > 0.93 and dot > best_dot:
			best_dot = dot
			best = n

	var hint := ""
	if best != null:
		hint = _get_interactable_name(best)

	_send_interact_hint(hint)


func _get_interactable_name(node: Node) -> String:
	if node == null:
		return ""
	if node.has_method("get_display_name"):
		return str(node.call("get_display_name"))
	if "display_name" in node:
		return str(node.display_name)
	return node.name


func _send_interact_hint(text: String) -> void:
	_interact_hint = text
	get_tree().call_group("hud", "set_interact_hint", text)


func _compute_wind_multiplier(direction: Vector3) -> float:
	if direction == Vector3.ZERO:
		return 1.0
	if _wind_dir_xz == Vector3.ZERO or _wind_speed_mps <= 0.01:
		return 1.0
	var dir_xz := Vector3(direction.x, 0.0, direction.z).normalized()
	if dir_xz == Vector3.ZERO:
		return 1.0
	var tail := dir_xz.dot(_wind_dir_xz)
	var wind_scale := (_wind_speed_mps / 32.0) * WIND_K
	var mul := 1.0 + tail * wind_scale
	return clamp(mul, WIND_MIN_MUL, WIND_MAX_MUL)


func set_wind_state(speed_mps: float, dir_xz: Vector3) -> void:
	_wind_speed_mps = max(speed_mps, 0.0)
	_wind_dir_xz = dir_xz.normalized() if dir_xz != Vector3.ZERO else Vector3.ZERO


func _apply_look() -> void:
	rotation_degrees.y = yaw
	if _camera:
		_camera.rotation_degrees.x = pitch


func _play_hands_action() -> void:
	if _hands and _hands.has_method("play_action"):
		_hands.call("play_action")


func _ensure_input_actions() -> void:
	if not InputMap.has_action("sprint"):
		InputMap.add_action("sprint")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_SHIFT
		InputMap.action_add_event("sprint", ev)

	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var ev_interact := InputEventKey.new()
		ev_interact.physical_keycode = KEY_E
		InputMap.action_add_event("interact", ev_interact)

	if not InputMap.has_action("place_trap"):
		InputMap.add_action("place_trap")
		var ev_trap := InputEventKey.new()
		ev_trap.physical_keycode = KEY_T
		InputMap.action_add_event("place_trap", ev_trap)

	var move_actions := {
		"move_forward": KEY_W,
		"move_backward": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
	}
	for action in move_actions.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			var ev_move := InputEventKey.new()
			ev_move.physical_keycode = move_actions[action]
			InputMap.action_add_event(action, ev_move)


func _place_trap() -> bool:
	if inventory == null:
		return false
	if inventory.count(TRAP_ITEM_ID) <= 0:
		_notify_hud("Нет ловушек")
		return false
	if TrapScene == null:
		return false

	var trap: Node3D = TrapScene.instantiate() as Node3D
	if trap == null:
		return false

	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()

	var spawn_pos: Vector3 = global_position + forward * 1.2
	spawn_pos.y = global_position.y - 0.9

	var root: Node = get_tree().current_scene
	if root == null:
		root = get_parent()
	if root == null:
		return false

	root.add_child(trap)
	trap.global_position = spawn_pos
	trap.rotation.y = rotation.y

	inventory.remove(TRAP_ITEM_ID, 1)
	_notify_hud("Ловушка установлена")
	return true


func set_ui_blocked(blocked: bool) -> void:
	ui_blocked = blocked


func get_stats() -> Dictionary:
	return {
		"hp": stats.health,
		"hp_max": 100.0,
		"body_temp": stats.body_temperature,
		"body_temp_min": 0.0,
		"body_temp_max": 100.0,
		"hunger": stats.hunger,
		"hunger_max": 100.0,
		"thirst": stats.thirst,
		"thirst_max": 100.0,
		"stamina": stats.stamina,
		"stamina_max": 100.0,
	}


func _notify_hud(text: String) -> void:
	get_tree().call_group("hud", "show_toast", text)


func _update_poison(delta: float) -> void:
	if _poison_damage_left <= 0.0:
		return
	_poison_tick_timer -= delta
	if _poison_tick_timer <= 0.0:
		_poison_tick_timer = 10.0
	var dmg: float = min(5.0, _poison_damage_left)
	_poison_damage_left = max(0.0, _poison_damage_left - dmg)
	stats.health = max(0.0, stats.health - dmg)
	if _poison_damage_left <= 0.0:
		_notify_hud("Пищевое отравление прошло")


func get_status_effects() -> Dictionary:
	return {
		"food_poisoning": _poison_damage_left > 0.0,
		"food_poisoning_left": _poison_damage_left,
	}


func butcher_carcass(slot_index: int) -> bool:
	if inventory == null:
		return false
	var slot: Dictionary = inventory.get_slot(slot_index) as Dictionary
	if slot == null:
		return false
	var id: String = str(slot.get("id", ""))
	if id != RABBIT_CARCASS_ID:
		return false
	var weight: float = float(slot.get("weight", 0.0))
	if weight <= 0.0:
		weight = 2.0
	var loss_pct: float = randf_range(0.15, 0.25)
	var lost: float = weight * loss_pct
	var meat_weight: float = max(0.1, weight - lost)
	inventory.set_slot(slot_index, null)
	var added: bool = inventory.add_item(RABBIT_MEAT_RAW_ID, meat_weight)
	if not added:
		_notify_hud("Нет места в инвентаре")
		return false
	_notify_hud("Было потеряно %.2f кг мяса при разделке голыми руками" % lost)
	return true


func eat_meat(slot_index: int, cooked: bool) -> bool:
	if inventory == null:
		return false
	var slot: Dictionary = inventory.get_slot(slot_index) as Dictionary
	if slot == null:
		return false
	var id: String = str(slot.get("id", ""))
	if cooked and id != RABBIT_MEAT_COOKED_ID:
		return false
	if (not cooked) and id != RABBIT_MEAT_RAW_ID:
		return false
	var weight: float = float(slot.get("weight", 0.0))
	if weight <= 0.0:
		weight = 1.0
	ui_blocked = true
	await get_tree().create_timer(2.0).timeout
	ui_blocked = false
	inventory.set_slot(slot_index, null)
	var hunger_restore: float = (weight * (25.0 if cooked else 15.0))
	stats.restore_hunger(hunger_restore)
	if cooked:
		_notify_hud("Жареное мясо съедено")
	else:
		_notify_hud("Сырое мясо съедено")
		if randf() < 0.5:
			_apply_food_poisoning()
	return true


func _apply_food_poisoning() -> void:
	_poison_damage_left = 75.0
	_poison_tick_timer = 10.0
	_notify_hud("Получено пищевое отравление! Избегай сырого мяса")
