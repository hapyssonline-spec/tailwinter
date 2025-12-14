extends Node3D

signal fuel_changed(current: float, max: float)

@export var warmth_restore_rate: float = 10.0 # скорость восстановления тепла в секунду
@export var fuel_max: float = 100.0           # максимальный запас топлива костра
@export var fuel: float = 60.0                # стартовое количество топлива
@export var burn_rate: float = 1.0            # сколько топлива сгорает в секунду
@export var fuel_per_wood: float = 20.0       # сколько топлива добавляет одно полено

var player_in_range: Node3D = null
var is_lit: bool = true

@onready var fire_mesh: Node3D = $Firemesh

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("campfire")
	is_lit = fuel > 0.0
	_update_fire_visual()
	fuel_changed.emit(fuel, fuel_max)


func _process(delta: float) -> void:
	_update_burning(delta)
	_restore_warmth(delta)


func _update_burning(delta: float) -> void:
	if not is_lit:
		return

	var prev_fuel := fuel
	fuel = max(0.0, fuel - burn_rate * delta)
	if fuel != prev_fuel:
		fuel_changed.emit(fuel, fuel_max)

	if fuel <= 0.0:
		_set_lit(false)


func _restore_warmth(delta: float) -> void:
	if player_in_range == null or not is_lit:
		return

	if "warmth" in player_in_range:
		player_in_range.warmth = min(
				100.0,
				player_in_range.warmth + warmth_restore_rate * delta
		)


func interact(actor: Node) -> void:
	if not actor:
		return

	if not ("player_wood" in actor):
		print("Не у кого брать дрова.")
		return

	if fuel >= fuel_max:
		print("Костёр уже заполнен.")
		return

	if actor.player_wood <= 0:
		print("Нет дров.")
		return

	actor.player_wood -= 1
	var prev_fuel := fuel
	fuel = clamp(fuel + fuel_per_wood, 0.0, fuel_max)
	if fuel > 0.0 and not is_lit:
		_set_lit(true)

	if fuel != prev_fuel:
		fuel_changed.emit(fuel, fuel_max)
		print("Костёр пополнен дровами. Текущее топливо: %.1f" % fuel)


func _on_warm_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = body
		if body.has_method("set_active_interactable"):
			body.set_active_interactable(self)


func _on_warm_area_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
	if body.name == "Player" and body.has_method("clear_active_interactable"):
		body.clear_active_interactable(self)


func _set_lit(value: bool) -> void:
	is_lit = value
	_update_fire_visual()
	if not is_lit:
		fuel_changed.emit(fuel, fuel_max)


func _update_fire_visual() -> void:
	if fire_mesh:
		fire_mesh.visible = is_lit
