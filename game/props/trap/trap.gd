extends Area3D

@export var animation_player_path: NodePath = NodePath("")
@export var idle_animation: StringName = &"Idle"
@export var trigger_animation: StringName = &"Close"
@export var lifetime_after_trigger: float = 120.0
@export var rabbit_group: String = "rabbits"
@export var albedo_path: String = "res://assets/3d/textures/props/Finished_Grasslands.png"

var _anim: AnimationPlayer
var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_anim = _find_animation_player()
	_apply_material()
	_play_idle()


func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if body == null:
		return
	var name_l := body.name.to_lower()
	var is_rabbit := body.is_in_group(rabbit_group) or name_l.find("rabbit") != -1
	if not is_rabbit:
		return

	_triggered = true
	_play_trigger()
	if body.has_method("on_trapped"):
		body.call_deferred("on_trapped")
	elif body.has_method("die"):
		body.call_deferred("die")

	if lifetime_after_trigger > 0.0:
		await get_tree().create_timer(lifetime_after_trigger).timeout
		queue_free()


func _spawn_carcass(body: Node) -> void:
	var carcass_scene := preload("res://game/props/resources/pickups/rabbit_carcass_pickup.tscn")
	var inst := carcass_scene.instantiate()
	if inst is Node3D:
		var n3d: Node3D = inst
		if is_instance_valid(body) and body is Node3D:
			n3d.global_transform = body.global_transform
		else:
			n3d.global_transform = global_transform
		n3d.global_position.y = n3d.global_position.y + 0.2
		var root: Node = get_tree().get_current_scene()
		if root == null:
			root = get_tree().root
		if root:
			root.call_deferred("add_child", n3d)


func _find_animation_player() -> AnimationPlayer:
	if animation_player_path != NodePath("") and has_node(animation_player_path):
		var n := get_node_or_null(animation_player_path)
		if n is AnimationPlayer:
			return n
	return _find_first_anim_player(self)


func _find_first_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_first_anim_player(child)
		if found:
			return found
	return null


func _play_idle() -> void:
	if _anim == null:
		return
	var anim_name := _pick_existing_anim(idle_animation)
	if anim_name != StringName():
		_anim.play(anim_name)


func _play_trigger() -> void:
	if _anim == null:
		return
	var anim_name := _pick_existing_anim(trigger_animation)
	if anim_name != StringName():
		_anim.play(anim_name)


func _pick_existing_anim(anim_name: StringName) -> StringName:
	if _anim == null:
		return StringName()
	if _anim.has_animation(anim_name):
		return anim_name
	var list := _anim.get_animation_list()
	if list.is_empty():
		return StringName()
	return list[0]


func _apply_material() -> void:
	if albedo_path.is_empty():
		return
	var tex: Texture2D = load(albedo_path)
	if tex == null:
		return

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.8

	for mesh in _find_meshes(self):
		if mesh.mesh == null:
			mesh.material_override = mat
			continue
		var surf_count: int = mesh.mesh.get_surface_count()
		if surf_count == 0:
			mesh.material_override = mat
		else:
			for i in range(surf_count):
				mesh.set_surface_override_material(i, mat)


func _find_meshes(node: Node) -> Array:
	var result: Array = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_meshes(child))
	return result
