extends Node3D

@export var albedo_path: String = "res://assets/3d/textures/characters/traveler_basecolor.jpg"
@export var run_anim_name: String = "walk"
@export var idle_anim_name: String = "idle"

var _anim_player: AnimationPlayer
var _anim_run: String = ""
var _anim_idle: String = ""
var _current_anim: String = ""

func _ready() -> void:
	var tex: Texture2D = load(albedo_path)
	if tex == null:
		return

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.9
	mat.metallic = 0.0

	_apply_material_recursive(self, mat)
	_hide_platform_mesh()
	_cache_anim_player()
	_pick_default_anims()
	_play_anim(_anim_idle)


func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		var surf_count := mi.get_surface_override_material_count()
		# Apply to all surfaces; if none present, set override.
		if surf_count == 0:
			mi.material_override = mat
		else:
			for i in mi.get_surface_override_material_count():
				mi.set_surface_override_material(i, mat)

	for child in node.get_children():
		_apply_material_recursive(child, mat)


func _hide_platform_mesh() -> void:
	# Heuristic: hide flat, wide meshes (likely the base platform from the import).
	for child in get_children():
		_hide_platform_mesh_recursive(child)


func _hide_platform_mesh_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		var aabb := mi.get_aabb()
		if aabb.size.y < 0.5 and aabb.size.x > 0.5 and aabb.size.z > 0.5:
			mi.visible = false
			return
		# Heuristic: if this is a single-surface cylinder from import, also hide.
		if mi.mesh and mi.mesh.get_surface_count() == 1:
			var mesh_aabb := mi.mesh.get_aabb()
			if mesh_aabb.size.y < 0.5 and mesh_aabb.size.x > 0.5 and mesh_aabb.size.z > 0.5:
				mi.visible = false
				return

	for c in node.get_children():
		_hide_platform_mesh_recursive(c)


func _cache_anim_player() -> void:
	_anim_player = _find_animation_player(self)


func _pick_default_anims() -> void:
	if _anim_player == null:
		return
	var anims := _anim_player.get_animation_list()
	if anims.is_empty():
		return
	print_debug("Hero animations:", anims)

	# Respect explicit names if provided.
	if run_anim_name != "" and run_anim_name in anims:
		_anim_run = run_anim_name
	if idle_anim_name != "" and idle_anim_name in anims:
		_anim_idle = idle_anim_name

	var lower: Array[String] = []
	for a in anims:
		lower.append(String(a).to_lower())
	for i in anims.size():
		var anim_name_local := anims[i]
		var l := lower[i]
		if _anim_run == "" and (l.find("run") != -1 or l.find("walk") != -1):
			_anim_run = anim_name_local
		if _anim_idle == "" and (l.find("idle") != -1 or l.find("stand") != -1):
			_anim_idle = anim_name_local
	# Fallbacks
	if _anim_run == "":
		_anim_run = anims[0]
	if _anim_idle == "":
		_anim_idle = anims[0]


func play_run() -> void:
	_play_anim(_anim_run)


func play_idle() -> void:
	_play_anim(_anim_idle)


func play_run_loop() -> void:
	_play_anim(_anim_run, true)


func stop_anim() -> void:
	if _anim_player:
		_anim_player.stop()
		_current_anim = ""


func _play_anim(anim_name: String, loop: bool = false) -> void:
	if _anim_player == null or anim_name == "":
		return
	if _current_anim == anim_name:
		return
	_current_anim = anim_name
	_set_loop(anim_name, loop)
	_anim_player.play(anim_name)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null


func _set_loop(anim_name: String, loop: bool) -> void:
	if _anim_player == null:
		return
	var anim: Animation = _anim_player.get_animation(anim_name)
	if anim:
		anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
