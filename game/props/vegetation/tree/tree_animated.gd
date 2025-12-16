extends Node3D


func _ready() -> void:
	_hide_leaves()
	var anim_player := _find_anim_player(self)
	if anim_player:
		var anim_list := anim_player.get_animation_list()
		if anim_list.is_empty():
			return
		var anim_name: StringName = anim_list[0]
		var anim: Animation = anim_player.get_animation(anim_name)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		anim_player.play(anim_name)


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_anim_player(child)
		if found:
			return found
	return null


func _hide_leaves() -> void:
	var stack: Array = [self]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Node3D:
			var lname := n.name.to_lower()
			if lname.find("leaf") != -1 or lname.find("foliage") != -1:
				n.visible = false
		for child in n.get_children():
			stack.append(child)
