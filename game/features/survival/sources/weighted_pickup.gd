extends Area3D

@export var resource_type: String = "rabbit_carcass"
@export var min_weight_kg: float = 1.5
@export var max_weight_kg: float = 3.5
@export var display_name: String = ""

var _player_in_range: Node = null
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		_player_in_range = body
		if body.has_method("register_interactable"):
			body.register_interactable(self)


func _on_body_exited(body: Node) -> void:
	if body == _player_in_range:
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
		_player_in_range = null


func on_interact(player: Node) -> bool:
	if player == null:
		return false
	if not ("inventory" in player):
		return false
	var weight := _rng.randf_range(min_weight_kg, max_weight_kg)
	if player.inventory.has_method("add_item"):
		var ok: bool = player.inventory.add_item(resource_type, weight)
		if ok:
			_queue_remove_from_player(player)
		return ok
	return false


func _queue_remove_from_player(player: Node) -> void:
	if player.has_method("unregister_interactable"):
		player.unregister_interactable(self)
	queue_free()


func get_display_name() -> String:
	if display_name != "":
		return display_name
	return resource_type.capitalize()
