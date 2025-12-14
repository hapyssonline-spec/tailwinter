extends CharacterBody3D

# ----- ДВИЖЕНИЕ -----
const SPEED: float = 5.0
const MIN_WIND_SPEED_MUL: float = 0.65
const MAX_WIND_SPEED_MUL: float = 1.35
const PLAYER_WIND_K: float = 0.4
const WIND_MAX_SPEED: float = 75.0

# ----- ПАРАМЕТРЫ ВЫЖИВАНИЯ -----
var health: float = 100.0
var warmth: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0

# скорость убывания (единиц в секунду)
const WARMTH_DECAY: float       = 2.0
const HUNGER_DECAY: float       = 0.5
const THIRST_DECAY: float       = 0.8
const HEALTH_COLD_DAMAGE: float = 3.0
const WARMTH_WIND_EXTRA_MAX: float = 6.0

# таймер для редкого вывода в консоль
var _log_timer: float = 0.0
var _wind: Node = null


func _ready() -> void:
        _wind = _find_wind_node()


func _physics_process(delta: float) -> void:
        _handle_movement(delta)
        _update_stats(delta)
        _log_stats(delta)


func _handle_movement(delta: float) -> void:
	# Вектор ввода: x (A/D), y (W/S)
	var input_vec: Vector2 = Vector2.ZERO
	input_vec.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vec.y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")

	var direction: Vector3 = Vector3.ZERO

	if input_vec != Vector2.ZERO:
		# Берём текущую активную 3D-камеру
		var cam: Camera3D = get_viewport().get_camera_3d()

		if cam != null:
			var basis: Basis = cam.global_transform.basis

			# Вперёд камеры (в Godot вперёд — минус Z)
			var forward: Vector3 = -basis.z
			var right: Vector3   =  basis.x

			# Проецируем на плоскость XZ
			forward.y = 0.0
			right.y   = 0.0

			forward = forward.normalized()
			right   = right.normalized()

			# Итоговое направление: «вперёд/назад» + «влево/вправо» от камеры
			direction = (right * input_vec.x + forward * input_vec.y).normalized()
		else:
			# Фоллбэк: без камеры – двигаемся по осям мира
			direction = Vector3(input_vec.x, 0.0, input_vec.y).normalized()

	# Применяем скорость по XZ
        if direction != Vector3.ZERO:
                var speed_multiplier: float = _calc_wind_speed_multiplier(direction)
                var final_speed: float = SPEED * speed_multiplier

                velocity.x = direction.x * final_speed
                velocity.z = direction.z * final_speed

                # Поворачиваем тело в сторону движения (для красоты; при капсуле не критично)
                look_at(global_position + direction, Vector3.UP)
        else:
                velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	# Пока без прыжков/гравитации
	velocity.y = 0.0

	move_and_slide()


func _update_stats(delta: float) -> void:
        # базовое убывание
        var wind_speed: float = _get_wind_speed()
        var extra_warmth_decay: float = pow(wind_speed / WIND_MAX_SPEED, 2.0) * WARMTH_WIND_EXTRA_MAX

        warmth -= (WARMTH_DECAY + extra_warmth_decay) * delta
        hunger -= HUNGER_DECAY * delta
        thirst -= THIRST_DECAY * delta

	warmth = clamp(warmth, 0.0, 100.0)
	hunger = clamp(hunger, 0.0, 100.0)
	thirst = clamp(thirst, 0.0, 100.0)

	# ----- УРОН ПО ЗДОРОВЬЮ -----
	var health_loss: float = 0.0

	# Замёрз — урон
	if warmth <= 0.0:
		health_loss += HEALTH_COLD_DAMAGE * delta

	# Сильный голод — урон (если голод <= 0)
	if hunger <= 0.0:
		health_loss += 2.0 * delta  # можешь потом подкрутить

	# Сильная жажда — урон (делаем сильнее, чем голод)
	if thirst <= 0.0:
		health_loss += 4.0 * delta

	health -= health_loss
	health = clamp(health, 0.0, 100.0)

	if health <= 0.0:
		_on_player_dead()


func _on_player_dead() -> void:
	print("Игрок умер. (пока просто сообщение, потом сделаем экран смерти)")


func _log_stats(delta: float) -> void:
        _log_timer += delta
        if _log_timer >= 1.0:
                _log_timer = 0.0
                print("HP: %.1f | Warmth: %.1f | Hunger: %.1f | Thirst: %.1f" % [health, warmth, hunger, thirst])


func _calc_wind_speed_multiplier(move_dir: Vector3) -> float:
        if move_dir == Vector3.ZERO:
                return 1.0

        var wind_node := _get_wind_node()
        if wind_node == null:
                return 1.0

        if not wind_node.has_method("get_wind_dir_xz") or not wind_node.has_method("get_wind_speed_mps"):
                return 1.0

        var move_dir_xz := Vector3(move_dir.x, 0.0, move_dir.z).normalized()
        if move_dir_xz == Vector3.ZERO:
                return 1.0

        var wind_dir: Vector3 = wind_node.get_wind_dir_xz()
        if wind_dir == Vector3.ZERO:
                return 1.0

        var tail: float = move_dir_xz.dot(wind_dir)
        var wind_speed: float = wind_node.get_wind_speed_mps()

        var speed_multiplier: float = 1.0 + tail * (wind_speed / WIND_MAX_SPEED) * PLAYER_WIND_K
        return clamp(speed_multiplier, MIN_WIND_SPEED_MUL, MAX_WIND_SPEED_MUL)


func _get_wind_speed() -> float:
        var wind_node := _get_wind_node()
        if wind_node != null and wind_node.has_method("get_wind_speed_mps"):
                return wind_node.get_wind_speed_mps()
        return 0.0


func _get_wind_node() -> Node:
        if _wind == null or not is_instance_valid(_wind):
                _wind = _find_wind_node()
        return _wind


func _find_wind_node() -> Node:
        var wind_nodes := get_tree().get_nodes_in_group("wind")
        if not wind_nodes.is_empty():
                return wind_nodes[0]
        if get_parent() != null and get_parent().has_node("Wind"):
                return get_parent().get_node("Wind")
        return null
