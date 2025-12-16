extends Node3D

@export var max_wood: float = 100.0
@export var burn_rate_per_sec: float = 0.8  # ~120 c на полном баке без ветра
@export var base_restore_rate: float = 8.0
@export var max_restore_rate: float = 16.0
@export var light_min_energy: float = 0.2
@export var light_max_energy: float = 3.0
@export var override_albedo: Texture2D
@export var override_roughness: float = 0.7
@export var override_metallic: float = 0.0
@export var wind_factor_max: float = 12.0
@export var stick_fuel_value: float = 12.0
@export var display_name: String = "Костёр"

const STICK_ITEM_ID := "stick"
const COOKED_ITEM_ID := "rabbit_meat_cooked"

@onready var light: OmniLight3D = $Light
@onready var particles: GPUParticles3D = $Particles

var player_in_range: Node3D = null
var wood: float = 100.0
var _wind_factor: float = 1.0
var cooking_weight: float = 0.0
var cooking_ready: float = 0.0
var cooking_time_total: float = 0.0
var cooking_time_left: float = 0.0


func _ready() -> void:
	wood = max_wood
	add_to_group("campfire")
	_apply_material_override()
	_update_visuals()


func _process(delta: float) -> void:
	wood = max(0.0, wood - burn_rate_per_sec * _wind_factor * delta)

	if player_in_range != null and wood > 0.0 and "stats" in player_in_range:
		var heat_rate: float = lerp(base_restore_rate, max_restore_rate, _burn_ratio())
		player_in_range.stats.restore_body_temperature(heat_rate * delta)

	_update_visuals()
	_process_cooking(delta)


func add_wood(amount: float) -> void:
	wood = clamp(wood + amount, 0.0, max_wood)
	_update_visuals()


func _burn_ratio() -> float:
	return clamp(wood / max_wood, 0.0, 1.0)


func _update_visuals() -> void:
	var ratio := _burn_ratio()

	if light:
		light.light_energy = lerp(light_min_energy, light_max_energy, ratio)

	if particles:
		particles.emitting = ratio > 0.01
		particles.amount = int(20 + ratio * 40)
		particles.process_material.initial_velocity_min = 0.5 + ratio * 1.0
		particles.process_material.initial_velocity_max = 1.5 + ratio * 1.5


func _apply_material_override() -> void:
	if override_albedo == null:
		return

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = override_albedo
	mat.roughness = override_roughness
	mat.metallic = override_metallic

	for mesh in _find_meshes(self):
		mesh.material_override = mat
		if mesh.mesh:
			for i in mesh.mesh.get_surface_count():
				mesh.set_surface_override_material(i, mat)


func _find_meshes(node: Node) -> Array:
	var res: Array = []
	if node is MeshInstance3D:
		res.append(node)
	for child in node.get_children():
		res.append_array(_find_meshes(child))
	return res


func _on_warm_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = body
		if body.has_method("register_interactable"):
			body.register_interactable(self)


func _on_warm_area_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)


func set_wind_factor(factor: float) -> void:
	_wind_factor = clamp(factor, 0.0, 1.0 + wind_factor_max)


func on_interact(_player: Node) -> bool:
	# Меню костра открывается через группу "campfire" на стороне игрока.
	return true


func _show_toast(player: Node, text: String) -> void:
	if player.has_method("_notify_hud"):
		player.call("_notify_hud", text)


func get_display_name() -> String:
	return display_name


func add_fuel_from_player(player: Node) -> bool:
	if player == null or not ("inventory" in player):
		return false
	if player.inventory.count(STICK_ITEM_ID) <= 0:
		return false
	player.inventory.remove(STICK_ITEM_ID, 1)
	add_wood(stick_fuel_value)
	return true


func start_cooking(weight: float) -> bool:
	if weight <= 0.01:
		return false
	if wood <= 0.0:
		return false
	if cooking_weight > 0.0:
		return false
	var t: float = clamp(weight / 3.5, 0.0, 1.0)
	cooking_time_total = lerp(10.0, 20.0, t)
	cooking_time_left = cooking_time_total
	cooking_weight = weight
	return true


func take_ready_meat(player: Node) -> bool:
	if cooking_ready <= 0.01:
		return false
	if player == null or not ("inventory" in player):
		return false
	var ok: bool = player.inventory.add_item(COOKED_ITEM_ID, cooking_ready)
	if ok:
		cooking_ready = 0.0
	return ok


func _process_cooking(delta: float) -> void:
	if cooking_weight <= 0.0:
		return
	if wood <= 0.0:
		return
	cooking_time_left = max(0.0, cooking_time_left - delta)
	if cooking_time_left <= 0.0:
		cooking_ready += cooking_weight
		cooking_weight = 0.0
		cooking_time_total = 0.0
