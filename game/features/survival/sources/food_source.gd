extends Node3D

@export var hunger_restore_rate: float = 12.0  # Скорость восстановления голода в зоне еды.

var player_in_range: Node3D = null


func _process(delta: float) -> void:
	if player_in_range == null:
		return

	if "stats" in player_in_range:
		player_in_range.stats.restore_hunger(hunger_restore_rate * delta)


func _on_eat_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = body


func _on_eat_area_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
