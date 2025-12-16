extends Node3D

@export var stick_texture: Texture2D = preload("res://assets/3d/models/_source/campfire/textures/Colour_pallete.png")


func _ready() -> void:
	_apply_material()


func _apply_material() -> void:
	if stick_texture == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = stick_texture
	mat.roughness = 0.6
	mat.metallic = 0.0

	for mesh in _collect_meshes(get_parent()):
		if mesh is MeshInstance3D:
			mesh.material_override = mat


func _collect_meshes(node: Node) -> Array:
	var res: Array = []
	if node is MeshInstance3D:
		res.append(node)
	for child in node.get_children():
		res.append_array(_collect_meshes(child))
	return res
