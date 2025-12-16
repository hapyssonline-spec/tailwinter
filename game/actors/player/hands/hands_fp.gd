extends Node3D

@export var idle_animation: String = "arms_armature|Hands_below"
@export var action_animation: String = "collect_something"

@onready var _anim_player: AnimationPlayer = _find_animation_player(self)
@onready var _visible_nodes: Array[Node3D] = _gather_meshes(self)

var _pending_hide: bool = false

func _ready() -> void:
	_select_available_anims()
	if _anim_player:
		_anim_player.animation_finished.connect(_on_anim_finished)
		if _anim_player.has_animation(idle_animation):
			_anim_player.play(idle_animation)
	_hide_hands()

func play_action() -> void:
	if _anim_player == null or not _anim_player.has_animation(action_animation):
		return
	_show_hands()
	_pending_hide = true
	_anim_player.stop()
	_anim_player.play(action_animation)

func _on_anim_finished(anim_name: StringName) -> void:
	if anim_name == action_animation:
		if _anim_player and _anim_player.has_animation(idle_animation):
			_anim_player.play(idle_animation)
		if _pending_hide:
			_pending_hide = false
			_hide_hands()

func _show_hands() -> void:
	for n in _visible_nodes:
		n.visible = true

func _hide_hands() -> void:
	for n in _visible_nodes:
		n.visible = false

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null

func _gather_meshes(node: Node) -> Array[Node3D]:
	var res: Array[Node3D] = []
	if node is Node3D and not (node is AnimationPlayer):
		res.append(node)
	for child in node.get_children():
		res.append_array(_gather_meshes(child))
	return res


func _select_available_anims() -> void:
	if _anim_player == null:
		return
	var list := _anim_player.get_animation_list()
	if not _anim_player.has_animation(idle_animation):
		if list.size() > 0:
			idle_animation = list[0]
	if not _anim_player.has_animation(action_animation):
		var fallback := idle_animation
		for anim_name in list:
			if anim_name != idle_animation:
				fallback = anim_name
				break
		action_animation = fallback
