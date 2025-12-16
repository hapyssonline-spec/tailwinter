extends Node3D

# Р Р€Р С—РЎР‚Р В°Р Р†Р В»Р ВµР Р…Р С‘Р Вµ РЎвЂ Р С‘Р С”Р В»Р С•Р С Р Т‘Р ВµР Р…РЎРЉ/Р Р…Р С•РЎвЂЎРЎРЉ Р С‘ Р С•Р В±Р Р…Р С•Р Р†Р В»Р ВµР Р…Р С‘Р Вµ HUD.

@onready var sun: DirectionalLight3D      = get_node_or_null("Sun")
@onready var world_env: WorldEnvironment  = get_node_or_null("WorldEnvironment")
@onready var player: Node3D               = get_node_or_null("Player")
@onready var hud: CanvasLayer             = get_node_or_null("HUD")
@onready var ground: Node3D               = get_node_or_null("Ground")
@onready var terrain: Node                = get_node_or_null("Ground")
@onready var blizzard_fx: Node3D          = get_node_or_null("BlizzardFX")
@onready var campfire: Node               = get_node_or_null("Campfire")
@export var blizzard_scene_path: String = "res://assets/3d/models/_source/snowstorm/source/0000srrl.blend"

@export var day_length: float = 120.0  # Р вЂќР В»Р С‘Р Р…Р В° РЎРѓРЎС“РЎвЂљР С•Р С” Р Р† РЎРѓР ВµР С”РЎС“Р Р…Р Т‘Р В°РЎвЂ¦.
var time_of_day: float = 0.5           # 0..1 (0 - Р Р…Р С•РЎвЂЎРЎРЉ, 0.5 - Р С—Р С•Р В»Р Т‘Р ВµР Р…РЎРЉ, ~0.75 - Р Р†Р ВµРЎвЂЎР ВµРЎР‚).

@export_group("Р РЋР С—Р В°Р Р†Р Р… Р Т‘Р ВµРЎР‚Р ВµР Р†РЎРЉР ВµР Р†")
@export var tree_scene: PackedScene
@export var tree_count: int = 20
@export var spawn_radius: float = 60.0
@export var spawn_min_distance_to_player: float = 8.0
@export var spawn_height_offset: float = 0.0
@export var spawn_seed: int = 1337
@export var spawn_scale_multiplier: float = 1.5
@export var stick_scene: PackedScene = preload("res://game/props/resources/pickups/stick_pickup.tscn")
@export var sticks_per_tree_min: int = 0
@export var sticks_per_tree_max: int = 2
@export var stick_spawn_radius_min: float = 0.6
@export var stick_spawn_radius_max: float = 1.6
@export var stick_spawn_height_offset: float = 0.05

@export_group("Environment props")
@export var env_pack_scene: PackedScene = preload("res://assets/3d/models/environment/foliage_seasonal_grp1.fbx")
@export var env_spawn_count: int = 60
@export var env_spawn_radius: float = 80.0
@export var env_min_distance_to_player: float = 6.0
@export var env_spawn_height_offset: float = 0.0
@export var env_min_scale: float = 0.6
@export var env_max_scale: float = 1.2

@export_group("Fauna")
@export var rabbit_scene: PackedScene = preload("res://game/actors/creatures/rabbit/rabbit.tscn")
@export var rabbit_count: int = 6
@export var rabbit_spawn_radius: float = 70.0
@export var rabbit_min_distance_to_player: float = 6.0
@export var rabbit_height_offset: float = 0.0
@export var blizzard_wind_speed_min: float = 10.0
@export var blizzard_wind_speed_max: float = 18.0


@export_group("Р СџР С•Р С–Р С•Р Т‘Р В°")
@export var weather_enabled: bool = true
@export var weather_min_duration: float = 45.0
@export var weather_max_duration: float = 120.0
@export var weather_seed: int = 9876
@export var blizzard_wind_threshold: float = 12.0
@export var fog_max_clear: float = 0.3
@export var fog_max_snow: float = 0.4
@export var fog_max_blizzard: float = 0.75
@export var weather_change_interval: float = 30.0
@export var weather_change_step: float = 0.1
@export var ambient_temp_min: float = -65.0
@export var ambient_temp_max: float = 0.0
@export var temp_change_interval_min: float = 60.0
@export var temp_change_interval_max: float = 150.0
@export var temp_smoothing: float = 0.2

enum WeatherType { CLEAR, SNOW }
var _current_weather: int = WeatherType.CLEAR
var _weather_timer: float = 0.0
var _weather_body_temp_mult: float = 1.0
var _weather_fog_add: float = 0.0
var _weather_fog_begin: float = 0.0
var _weather_light_mult: float = 1.0
var _weather_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _weather_changed_flag: bool = false
var _weather_fog_end: float = 150.0
var _weather_time_since_change: float = 0.0
var _weather_change_chance: float = 0.0
var _blizzard_scene_root: Node3D
var _blizzard_scene_particles: Array[Node3D] = []
var _wind: Node = null
@export var wind_scene: PackedScene
@export var warm_wind_extra_max: float = 4.0
@export var fire_wind_factor_max: float = 12.0

var _env_prototypes: Array[PackedScene] = []
var _debug_enabled: bool = false
var _debug_layer: CanvasLayer
var _debug_label: Label
var _debug_wireframe: WorldEnvironment
var _debug_collision_visible: bool = false
var _debug_fps: float = 0.0
var _debug_update_timer: float = 0.0
var _wind_speed_cache: float = 0.0
var _wind_dir_cache: Vector3 = Vector3.ZERO
var _ambient_temp_c: float = -20.0
var _target_temp_c: float = -20.0
var _temp_timer: float = 0.0
var _temp_next_interval: float = 90.0

const DEBUG_TIME_RATE: float = 0.4


func _process(delta: float) -> void:
	if not _debug_collision_visible:
		get_tree().debug_collisions_hint = false
	_handle_debug_input(delta)
	_apply_wind_effects(delta)
	_update_weather(delta)
	_update_day_night(delta)
	_update_temperature(delta)
	if _debug_enabled:
		_debug_update_timer += delta
		if _debug_update_timer >= 0.25:
			_debug_update_timer = 0.0
			_debug_fps = Engine.get_frames_per_second()
			_update_debug_overlay_text()

	if hud != null and player != null and "stats" in player:
		hud.update_stats(player.stats)
		if "inventory" in player and hud.has_method("update_inventory"):
			hud.update_inventory(player.inventory)


func _get_height(x: float, z: float) -> float:
	if _has_height_provider():
		return terrain.get_height_at(x, z)
	return 0.0


func _has_height_provider() -> bool:
	return terrain != null and terrain.has_method("get_height_at")


func _toggle_collision_debug(_enabled: bool) -> void:
	get_tree().debug_collisions_hint = false
	if get_viewport():
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED


func _generate_ground_collision() -> void:
	if ground == null:
		return
	if ground.has_node("GroundCollision"):
		return

	var meshes := _find_meshes(ground)
	if meshes.is_empty():
		return

	var body := StaticBody3D.new()
	body.name = "GroundCollision"
	ground.add_child(body)

	for mesh in meshes:
		if mesh.mesh == null:
			continue
		var shape: Shape3D = mesh.mesh.create_trimesh_shape()
		if shape == null:
			continue
		var cs := CollisionShape3D.new()
		cs.shape = shape
		cs.transform = mesh.transform
		body.add_child(cs)


func _find_meshes(node: Node) -> Array:
	var res: Array = []
	if node is MeshInstance3D:
		res.append(node)
	for child in node.get_children():
		res.append_array(_find_meshes(child))
	return res


func _snap_player_to_ground() -> void:
	if player == null or not is_instance_valid(player):
		return

	var space := get_world_3d().direct_space_state
	var origin := player.global_position + Vector3(0, 5.0, 0)
	var target := origin + Vector3(0, -200.0, 0)
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.collide_with_areas = false
	query.exclude = [player]

	var result := space.intersect_ray(query)
	if not result.has("position"):
		return

	var hit_pos: Vector3 = result.position
	var offset := _get_height_offset(player) if player is PhysicsBody3D else 0.0
	player.global_position = hit_pos + Vector3(0, offset, 0)


func _init_wind() -> void:
	if wind_scene != null:
		var inst := wind_scene.instantiate()
		if inst:
			inst.name = "Wind"
			add_child(inst)
			inst.add_to_group("wind")
			_wind = inst
			return

	if _wind == null:
		var script := preload("res://game/world/wind.gd")
		var w := script.new()
		w.name = "Wind"
		add_child(w)
		w.add_to_group("wind")
		_wind = w


func _load_blizzard_scene() -> void:
	if blizzard_scene_path.is_empty():
		return
	if not ResourceLoader.exists(blizzard_scene_path):
		return

	var packed: PackedScene = load(blizzard_scene_path)
	if packed == null:
		return

	var inst := packed.instantiate()
	if inst == null or not (inst is Node3D):
		return

	_blizzard_scene_root = inst
	add_child(inst)
	inst.process_mode = Node.PROCESS_MODE_DISABLED

	_cleanup_blizzard_scene(inst)


func _cleanup_blizzard_scene(root: Node) -> void:
	_blizzard_scene_particles.clear()
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			continue
		if n is GPUParticles3D or n is CPUParticles3D:
			_blizzard_scene_particles.append(n)
		for child in n.get_children():
			stack.append(child)


func _ready() -> void:
	get_tree().debug_collisions_hint = false
	ProjectSettings.set_setting("debug/physics/visible_collision_shapes", false)
	add_to_group("world")
	_weather_rng.seed = weather_seed
	_pick_next_weather()
	_pick_next_temperature()
	_generate_ground_collision()
	_snap_player_to_ground()
	_load_blizzard_scene()
	_spawn_trees()
	_prepare_env_prototypes()
	_spawn_environment_props()
	_spawn_rabbits()
	_snap_objects_to_ground()
	_ensure_debug_actions()
	_create_debug_overlay()
	_init_wind()


func _update_day_night(delta: float) -> void:
	# Р РЋР Т‘Р Р†Р С‘Р С–Р В°Р ВµР С Р Р†РЎР‚Р ВµР СРЎРЏ РЎРѓРЎС“РЎвЂљР С•Р С”.
	time_of_day = fposmod(time_of_day + delta / day_length, 1.0)

	# Р вЂ™РЎР‚Р В°РЎвЂ°Р В°Р ВµР С РЎРѓР С•Р В»Р Р…РЎвЂ Р Вµ Р С—Р С• Р С•РЎРѓР С‘ X: Р С•РЎвЂљ -30Р’В° Р Т‘Р С• 210Р’В° Р В·Р В° РЎвЂ Р С‘Р С”Р В».
	var angle: float = lerp(-30.0, 210.0, time_of_day)
	sun.rotation_degrees.x = angle

	# Р СљР ВµРЎР‚Р В° Р С•РЎРѓР Р†Р ВµРЎвЂ°РЎвЂР Р…Р Р…Р С•РЎРѓРЎвЂљР С‘ (0 - Р Р…Р С•РЎвЂЎРЎРЉ, 1 - Р СР В°Р С”РЎРѓР С‘Р СРЎС“Р С).
	var daylight: float = clamp(sin((time_of_day - 0.25) * TAU) * 0.5 + 0.5, 0.0, 1.0)

	# Р ВР Р…РЎвЂљР ВµР Р…РЎРѓР С‘Р Р†Р Р…Р С•РЎРѓРЎвЂљРЎРЉ РЎРѓР Р†Р ВµРЎвЂљР В°.
	var min_light: float = 0.05
	var max_light: float = 1.5
	sun.light_energy = lerp(min_light, max_light, daylight) * _weather_light_mult

	# Ambient Р С‘ РЎвЂљРЎС“Р СР В°Р Р….
	var env: Environment = world_env.environment
	if env != null:
		env.ambient_light_energy = lerp(0.1, 0.6, daylight) * _weather_light_mult
		env.fog_density = clamp(lerp(0.06, 0.02, daylight) + _weather_fog_add, 0.0, 1.0)
		env.fog_depth_begin = _weather_fog_begin
		env.fog_depth_end = _weather_fog_end


func _spawn_trees() -> void:
	if not _has_height_provider():
		return
	if tree_scene == null:
		return

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = spawn_seed

	for i in tree_count:
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(spawn_min_distance_to_player, spawn_radius)
		var pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		pos.y = _get_height(pos.x, pos.z)

		var tree := tree_scene.instantiate()
		tree.position = pos + Vector3(0, spawn_height_offset, 0)
		tree.scale *= spawn_scale_multiplier / 3.0

		add_child(tree)
		_spawn_sticks_near(pos, rng)


func _prepare_env_prototypes() -> void:
	_env_prototypes.clear()
	if env_pack_scene == null:
		return

	var root: Node = env_pack_scene.instantiate()
	if root == null:
		return

	for child in root.get_children():
		if not (child is Node3D):
			continue
		var stats := _analyze_env_node(child)
		# Берём только те, где есть и база, и снег.
		if stats.base_count <= 0 or stats.snow_count <= 0:
			continue

		var packed := PackedScene.new()
		var dup_child: Node = child.duplicate()
		if dup_child == null:
			continue
		if packed.pack(dup_child) == OK:
			_env_prototypes.append(packed)

	root.queue_free()


func _node_has_mesh(node: Node) -> bool:
	if node is MeshInstance3D:
		return true
	for child in node.get_children():
		if _node_has_mesh(child):
			return true
	return false


func _is_snow_part(part_name: String) -> bool:
	for t in ["snow", "cap", "pile", "chunk", "snowy", "frost"]:
		if part_name.find(t) != -1:
			return true
	return false


func _is_base_part(part_name: String) -> bool:
	for t in ["rock", "stone", "tree", "trunk", "stump", "log", "branch", "bush", "pine", "spruce", "fir", "wood"]:
		if part_name.find(t) != -1:
			return true
	return false


func _analyze_env_node(node: Node) -> Dictionary:
	var base_count := 0
	var snow_count := 0
	var mesh_count := 0

	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			mesh_count += 1
			var lname := n.name.to_lower()
			if _is_base_part(lname):
				base_count += 1
			if _is_snow_part(lname):
				snow_count += 1
		for child in n.get_children():
			stack.append(child)

	return {
		"base_count": base_count,
		"snow_count": snow_count,
		"mesh_count": mesh_count,
	}


func _spawn_environment_props() -> void:
	if not _has_height_provider():
		return
	if _env_prototypes.is_empty():
		return

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(spawn_seed) + 12345

	for i in env_spawn_count:
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(env_min_distance_to_player, env_spawn_radius)
		var pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		pos.y = _get_height(pos.x, pos.z) + env_spawn_height_offset

		var proto_index := rng.randi_range(0, _env_prototypes.size() - 1)
		var scene: PackedScene = _env_prototypes[proto_index]
		var instance := scene.instantiate()
		if instance == null or not (instance is Node3D):
			continue

		var scale_val := rng.randf_range(env_min_scale, env_max_scale)
		var n3d: Node3D = instance
		n3d.scale *= scale_val * spawn_scale_multiplier
		n3d.rotation.y = rng.randf_range(0.0, TAU)
		n3d.position = pos

		add_child(n3d)


func _spawn_rabbits() -> void:
	if not _has_height_provider():
		return
	if rabbit_scene == null:
		return

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(spawn_seed) + 2025

	for i in rabbit_count:
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(rabbit_min_distance_to_player, rabbit_spawn_radius)
		var pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		pos.y = _get_height(pos.x, pos.z) + rabbit_height_offset

		var rabbit := rabbit_scene.instantiate()
		if rabbit is Node3D:
			var n3d: Node3D = rabbit
			n3d.position = pos
			add_child(n3d)


func _spawn_sticks_near(tree_pos: Vector3, rng: RandomNumberGenerator) -> void:
	if not _has_height_provider():
		return
	if stick_scene == null:
		return
	var min_count: int = max(0, sticks_per_tree_min)
	var max_count: int = max(min_count, sticks_per_tree_max)
	var count := rng.randi_range(min_count, max_count)
	for i in count:
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(stick_spawn_radius_min, stick_spawn_radius_max)
		var pos := tree_pos + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		pos.y = _get_height(pos.x, pos.z) + stick_spawn_height_offset
		var stick := stick_scene.instantiate()
		if stick is Node3D:
			var n3d: Node3D = stick
			n3d.position = pos
			n3d.rotation.y = rng.randf_range(0.0, TAU)
			add_child(n3d)


func _snap_objects_to_ground() -> void:
	if not _has_height_provider():
		return

	var nodes := [
		"Player",
		"Campfire",
		"watersource",
		"FoodSource",
		"PickupWood",
		"PickupStone",
		"PickupBerries",
	]

	for path in nodes:
		if not has_node(path):
			continue
		var n := get_node(path)
		if n is Node3D:
			var obj: Node3D = n
			var h := _get_height(obj.position.x, obj.position.z)
			var extra_y := _get_height_offset(obj)
			obj.position.y = h + extra_y


func _update_weather(delta: float) -> void:
	if not weather_enabled:
		return

	_weather_time_since_change += delta

	if _weather_time_since_change >= weather_change_interval:
		var steps := int(floor(_weather_time_since_change / weather_change_interval))
		_weather_time_since_change = fmod(_weather_time_since_change, weather_change_interval)
		_weather_change_chance = clamp(_weather_change_chance + weather_change_step * float(steps), 0.0, 1.0)

		if _weather_rng.randf() < _weather_change_chance:
			_toggle_weather_state()
			_reset_weather_change_progress()
			_weather_changed_flag = true

	_apply_weather_effects(_weather_changed_flag)
	_weather_changed_flag = false


func _pick_next_weather() -> void:
	if _weather_rng.randf() < 0.5:
		_current_weather = WeatherType.CLEAR
	else:
		_current_weather = WeatherType.SNOW
	_reset_weather_change_progress()
	_weather_changed_flag = true


func _toggle_weather_state() -> void:
	if _current_weather == WeatherType.CLEAR:
		_current_weather = WeatherType.SNOW
	else:
		_current_weather = WeatherType.CLEAR


func _reset_weather_change_progress() -> void:
	_weather_time_since_change = 0.0
	_weather_change_chance = 0.0


func _apply_weather_effects(weather_changed: bool = false) -> void:
	var wind_speed: float = _wind_speed_cache
	var wind_ratio: float = clamp(wind_speed / 32.0, 0.0, 1.0)
	var is_blizzard: bool = _current_weather == WeatherType.SNOW and wind_speed >= blizzard_wind_threshold

	match _current_weather:
		WeatherType.CLEAR:
			_weather_body_temp_mult = 1.0
			_weather_fog_add = fog_max_clear * wind_ratio
			_weather_light_mult = 1.0
			_weather_fog_begin = 0.5
			_weather_fog_end = 150.0
		WeatherType.SNOW:
			_weather_body_temp_mult = 1.5 if is_blizzard else 1.2
			_weather_light_mult = 0.7 if is_blizzard else 0.9
			var fog_cap := fog_max_blizzard if is_blizzard else fog_max_snow
			# Максимум тумана плавно к 32 м/с (как прежний максимум на 16 м/с), без резкого клипа.
			var base_factor: float = clamp(wind_speed / 32.0, 0.0, 1.0)
			_weather_fog_add = fog_cap * base_factor
			# Дистанция видимости: от 120 м до ~40 м к 32 м/с.
			var fog_end_far: float = 120.0
			var fog_end_near: float = 40.0
			var t_fog: float = clamp(wind_speed / 32.0, 0.0, 1.0)
			_weather_fog_end = lerp(fog_end_far, fog_end_near, t_fog)
			# Начало тумана ближе к игроку при росте ветра для мягкого слоя.
			_weather_fog_begin = lerp(0.5, 8.0, t_fog)

	if player != null and "stats" in player:
		player.stats.set_body_temperature_multiplier(_weather_body_temp_mult)

	_update_blizzard_fx_state(weather_changed, is_blizzard, wind_speed, _wind_dir_cache)


func _update_temperature(delta: float) -> void:
	_temp_timer += delta
	if _temp_timer >= _temp_next_interval:
		_pick_next_temperature()
	_temp_next_interval = clamp(_temp_next_interval, temp_change_interval_min, temp_change_interval_max)
	_ambient_temp_c = lerp(_ambient_temp_c, _target_temp_c, clamp(temp_smoothing * delta, 0.0, 1.0))


func _pick_next_temperature() -> void:
	_temp_timer = 0.0
	_temp_next_interval = randf_range(temp_change_interval_min, temp_change_interval_max)
	_target_temp_c = _sample_temperature()


func _sample_temperature() -> float:
	# Основной диапазон чаще: -35..-15 (около 55%)
	var roll := randf()
	if roll < 0.55:
		return randf_range(-35.0, -15.0)
	elif roll < 0.7:
		return randf_range(-45.0, -35.0)
	elif roll < 0.85:
		return randf_range(-15.0, -5.0)
	elif roll < 0.93:
		return randf_range(-55.0, -45.0)
	elif roll < 0.97:
		return randf_range(-65.0, -55.0)
	else:
		return randf_range(-5.0, 0.0)


func _update_blizzard_fx_state(_weather_changed: bool, is_blizzard: bool, wind_speed: float, wind_dir: Vector3) -> void:
	var fx_nodes := [blizzard_fx]
	var dir := wind_dir
	if dir.length() < 0.001:
		dir = Vector3(0.0, -0.2, 0.0)
	dir = Vector3(dir.x, -0.2, dir.z).normalized()

	for fx in fx_nodes:
		if fx == null or not is_instance_valid(fx):
			continue

		if fx.has_method("set_active"):
			fx.call("set_active", is_blizzard)

		if not is_blizzard:
			if fx.has_method("set_wind"):
				fx.call("set_wind", dir, 0.0)
			continue

		if fx.has_method("set_wind"):
			fx.call("set_wind", dir, wind_speed)

	var scene_on := _blizzard_scene_root != null and is_instance_valid(_blizzard_scene_root) and is_blizzard
	if _blizzard_scene_root:
		_blizzard_scene_root.process_mode = Node.PROCESS_MODE_INHERIT if scene_on else Node.PROCESS_MODE_DISABLED
	for p in _blizzard_scene_particles:
		if not is_instance_valid(p):
			continue
		if p is GPUParticles3D or p is CPUParticles3D:
			p.emitting = scene_on
			if scene_on and p.has_method("restart"):
				p.call_deferred("restart")


func _get_wind_node() -> Node:
	if _wind != null and is_instance_valid(_wind):
		return _wind
	var candidates := get_tree().get_nodes_in_group("wind")
	if candidates.size() > 0:
		_wind = candidates[0]
		return _wind
	return null


func _apply_wind_effects(_delta: float) -> void:
	var wind_node := _get_wind_node()
	if wind_node == null:
		_wind_speed_cache = 0.0
		_wind_dir_cache = Vector3.ZERO
		_apply_wind_to_player(0.0, Vector3.ZERO)
		_apply_wind_to_campfire(0.0)
		return

	var speed: float = 0.0
	var dir: Vector3 = Vector3.ZERO
	if wind_node.has_method("get_wind_speed_mps"):
		speed = float(wind_node.call("get_wind_speed_mps"))
	if wind_node.has_method("get_wind_dir_xz"):
		dir = wind_node.call("get_wind_dir_xz")

	_wind_speed_cache = speed
	_wind_dir_cache = dir
	_apply_wind_to_player(speed, dir)
	_apply_wind_to_campfire(speed)


func _apply_wind_to_player(speed: float, dir: Vector3) -> void:
	if player == null or not is_instance_valid(player):
		return
	if player.has_method("set_wind_state"):
		player.call("set_wind_state", speed, dir)

	if player != null and "stats" in player:
		var stats_obj = player.stats
		if stats_obj != null:
			var extra := pow(speed / 75.0, 2.0) * warm_wind_extra_max
			if stats_obj.has_method("set_wind_chill"):
				stats_obj.set_wind_chill(extra)


func _apply_wind_to_campfire(speed: float) -> void:
	if campfire == null or not is_instance_valid(campfire):
		return

	if campfire.has_method("set_wind_factor"):
		var factor := 1.0 + pow(speed / 32.0, 3.0) * fire_wind_factor_max
		campfire.call("set_wind_factor", factor)


func get_air_temperature_c() -> float:
	return _ambient_temp_c


func get_feels_like_temperature_c() -> float:
	var wind_penalty: float = clamp(_wind_speed_cache / 32.0, 0.0, 1.0) * 15.0
	return _ambient_temp_c - wind_penalty


func _nudge_wind_speed(delta_speed: float) -> void:
	var wind_node := _get_wind_node()
	if wind_node == null:
		return
	if wind_node.has_method("nudge_target_speed"):
		wind_node.call("nudge_target_speed", delta_speed)


func _get_height_offset(obj: Node3D) -> float:
	if obj.has_meta("height_offset"):
		return float(obj.get_meta("height_offset"))

	if obj is PhysicsBody3D:
		var shape := _get_direct_shape(obj)
		if shape is CapsuleShape3D:
			var capsule: CapsuleShape3D = shape
			return capsule.radius + capsule.height * 0.5 + 0.1
		if shape is SphereShape3D:
			var sphere: SphereShape3D = shape
			return sphere.radius + 0.05
		if shape is BoxShape3D:
			var box: BoxShape3D = shape
			return box.size.y * 0.5 + 0.05

	return 0.3


func _get_direct_shape(body: PhysicsBody3D) -> Shape3D:
	for child in body.get_children():
		if child is CollisionShape3D:
			var cs: CollisionShape3D = child
			if cs.shape != null:
				return cs.shape
	return null


func _handle_debug_input(delta: float) -> void:
	if Input.is_action_just_pressed("debug_toggle"):
		_debug_enabled = not _debug_enabled
		if not _debug_enabled and _debug_collision_visible:
			_debug_collision_visible = false
			_toggle_collision_debug(false)
		if _debug_layer:
			_debug_layer.visible = _debug_enabled
		if _debug_label:
			_update_debug_overlay_text()

	if not _debug_enabled:
		return

	if Input.is_action_pressed("debug_time_forward"):
		time_of_day = fposmod(time_of_day + DEBUG_TIME_RATE * delta, 1.0)
		_update_debug_overlay_text()
	elif Input.is_action_pressed("debug_time_backward"):
		time_of_day = fposmod(time_of_day - DEBUG_TIME_RATE * delta + 1.0, 1.0)
		_update_debug_overlay_text()

	if Input.is_action_just_pressed("debug_toggle_collision"):
		_debug_collision_visible = not _debug_collision_visible
		_toggle_collision_debug(_debug_collision_visible)
		_update_debug_overlay_text()

	if Input.is_action_just_pressed("debug_weather_clear"):
		_set_weather(WeatherType.CLEAR)
	if Input.is_action_just_pressed("debug_weather_snow"):
		_set_weather(WeatherType.SNOW)
	if Input.is_action_just_pressed("debug_wind_up"):
		_nudge_wind_speed(2.0)
	if Input.is_action_just_pressed("debug_wind_down"):
		_nudge_wind_speed(-2.0)


func _set_weather(weather: int) -> void:
	_current_weather = weather
	_reset_weather_change_progress()
	_weather_changed_flag = true
	_apply_weather_effects(true)
	_update_debug_overlay_text()


func _create_debug_overlay() -> void:
	_debug_layer = CanvasLayer.new()
	add_child(_debug_layer)

	var panel := PanelContainer.new()
	panel.name = "DebugPanel"
	panel.modulate = Color(1, 1, 1, 0.85)
	panel.custom_minimum_size = Vector2(260, 0)
	panel.size_flags_horizontal = Control.SIZE_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)

	_debug_label = Label.new()
	_debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_debug_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_debug_label.size_flags_horizontal = Control.SIZE_FILL
	_debug_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_debug_label.custom_minimum_size = Vector2(240, 0)

	margin.add_child(_debug_label)
	panel.add_child(margin)
	_debug_layer.add_child(panel)
	panel.position = Vector2(16, 16)

	_debug_wireframe = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.adjustment_enabled = false
	env.glow_enabled = false
	_debug_wireframe.environment = env
	add_child(_debug_wireframe)
	_toggle_collision_debug(false)

	_debug_layer.visible = _debug_enabled
	_update_debug_overlay_text()


func _update_debug_overlay_text() -> void:
	if _debug_label == null:
		return

	var weather_name: String = "snow"
	if _current_weather == WeatherType.CLEAR:
		weather_name = "clear"
	var text: String = "DEV MODE (F3)\n"
	text += "FPS: %.0f\n" % _debug_fps
	text += "Time: %.2f\n" % time_of_day
	text += "Weather: %s\n" % weather_name
	text += "Wind: %.1f m/s\n" % _wind_speed_cache
	text += "Temp: %.1fC (feels: %.1fC)\n" % [get_air_temperature_c(), get_feels_like_temperature_c()]
	text += "Controls:\n"
	text += " [F3] toggle debug\n"
	text += " [1/2] clear/snow\n"
	text += " [+/-] wind +/-\n"
	text += " [[ / ]] time -/+\n"
	text += " [F4] collisions: %s" % ("on" if _debug_collision_visible else "off")

	_debug_label.text = text

func _ensure_debug_actions() -> void:
	var actions := {
		"debug_toggle": KEY_F3,
		"debug_time_forward": KEY_BRACKETRIGHT,
		"debug_time_backward": KEY_BRACKETLEFT,
		"debug_toggle_collision": KEY_F4,
		"debug_weather_clear": KEY_1,
		"debug_weather_snow": KEY_2,
		"debug_wind_up": KEY_EQUAL,
		"debug_wind_down": KEY_MINUS,
	}


	for action_name in actions.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		if InputMap.action_get_events(action_name).is_empty():
			var ev := InputEventKey.new()
			ev.physical_keycode = actions[action_name]
			InputMap.action_add_event(action_name, ev)
