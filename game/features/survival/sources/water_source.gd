extends Node3D

@export var thirst_restore_rate: float = 15.0  # Скорость восстановления жажды у игрока.

var player_in_range: Node3D = null


func _process(delta: float) -> void:
	if player_in_range == null:
		return

	if "stats" in player_in_range:
		player_in_range.stats.restore_thirst(thirst_restore_rate * delta)


func _on_drink_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = body


func _on_drink_area_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
