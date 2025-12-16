@tool
extends EditorScript

# Настройки
const MODELS_DIR := "res://assets/3d/models/props"
const OUT_DIR    := "res://scenes/props"

# true = триангл-коллизия (точная, тяжелее)
# false = выпуклая (быстрее, но грубее)
const USE_TRIMESH_COLLISION := true

func _run() -> void:
	_ensure_dir(OUT_DIR)

	var dir := DirAccess.open(MODELS_DIR)
	if dir == null:
		push_error("Cannot open models dir: %s" % MODELS_DIR)
		return

	dir.list_dir_begin()
	var name := dir.get_next()
	var created := 0
	while name != "":
		if dir.current_is_dir():
			name = dir.get_next()
			continue

		var path := MODELS_DIR.path_join(name)
		var ext := path.get_extension().to_lower()

		# Поддерживаемые форматы (лучше glb/gltf; fbx тоже возможен через импорт)
		if ext in ["glb", "gltf", "fbx"]:
			var base := name.get_basename()
			var out_scene := OUT_DIR.path_join(base + ".tscn")

			if FileAccess.file_exists(out_scene):
				name = dir.get_next()
				continue

			if _create_wrapper_scene(path, out_scene, base):
				created += 1

		name = dir.get_next()

	dir.list_dir_end()
	print("Done. Created scenes: %d" % created)


func _create_wrapper_scene(model_path: String, out_scene_path: String, base_name: String) -> bool:
	var packed := load(model_path)
	if packed == null:
		push_error("Failed to load model: %s" % model_path)
		return false

	var root := Node3D.new()
	root.name = base_name

	var instance: Node = null

	# В зависимости от импорта модель может быть PackedScene или ресурс другого типа.
	if packed is PackedScene:
		instance = (packed as PackedScene).instantiate()
	else:
		# На практике для 3D обычно будет PackedScene после импорта.
		push_error("Model is not a PackedScene (check import): %s" % model_path)
		root.free()
		return false

	instance.name = "Model"
	root.add_child(instance)
	instance.owner = root

	# Пытаемся найти MeshInstance3D внутри и сделать коллизию
	var mesh_instances := []
	_collect_mesh_instances(instance, mesh_instances)

	if mesh_instances.size() > 0:
		for mi in mesh_instances:
			if mi is MeshInstance3D:
				var mesh_i := mi as MeshInstance3D
				if USE_TRIMESH_COLLISION:
					mesh_i.create_trimesh_collision()
				else:
					mesh_i.create_convex_collision()

		# Важно: create_*_collision создаёт StaticBody3D/CollisionShape3D как children mesh-ноды.
		# Проставим owner, чтобы всё сохранилось в сцену.
		_fix_owners_recursive(root, root)

	var scene := PackedScene.new()
	var ok := scene.pack(root)
	if not ok:
		push_error("Failed to pack scene for: %s" % model_path)
		root.free()
		return false

	var err := ResourceSaver.save(scene, out_scene_path)
	if err != OK:
		push_error("Failed to save scene: %s (err=%d)" % [out_scene_path, err])
		root.free()
		return false

	root.free()
	return true


func _collect_mesh_instances(node: Node, out: Array) -> void:
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		_collect_mesh_instances(c, out)


func _fix_owners_recursive(node: Node, owner: Node) -> void:
	node.owner = owner
	for c in node.get_children():
		_fix_owners_recursive(c, owner)


func _ensure_dir(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		return
	DirAccess.make_dir_recursive_absolute(path)
