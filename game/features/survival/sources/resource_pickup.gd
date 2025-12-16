extends Area3D

@export var resource_type: String = "wood"
@export var amount: int = 1
@export var display_name: String = ""

var _player_in_range: Node = null


func _ready() -> void:
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

	player.inventory.add(resource_type, amount)
	_queue_remove_from_player(player)
	return true


func _queue_remove_from_player(player: Node) -> void:
	if player.has_method("unregister_interactable"):
		player.unregister_interactable(self)
	queue_free()


func get_display_name() -> String:
	if display_name != "":
		return display_name
	return resource_type.capitalize()
