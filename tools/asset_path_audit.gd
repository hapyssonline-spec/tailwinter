@tool
extends EditorScript

const SCAN_EXTENSIONS := ["tscn", "tres"]
const IGNORE_DIRS := [
	"res://.git",
	"res://.godot",
	"res://backups",
]


func _run() -> void:
	var missing: Array = []
	var regex := RegEx.new()
	regex.compile("res://[^\\s\"'>)]+")

	for file_path in _collect_files("res://"):
		var text := FileAccess.get_file_as_string(file_path)
		if text.is_empty():
			continue

		for match in regex.search_all(text):
			var path := match.get_string()
			if _should_skip(path):
				continue
			if not FileAccess.file_exists(path):
				missing.append({"file": file_path, "path": path})

	if missing.is_empty():
		print("asset_path_audit: OK (no missing paths).")
	else:
		print("asset_path_audit: missing paths:")
		for entry in missing:
			print("  %s -> %s" % [entry.file, entry.path])


func _collect_files(base: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(base)
	if dir == null:
		return result

	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full_path := base.path_join(name)
		if dir.current_is_dir():
			if _is_ignored_dir(full_path):
				name = dir.get_next()
				continue
			result.append_array(_collect_files(full_path))
		else:
			if name.get_extension().to_lower() in SCAN_EXTENSIONS:
				result.append(full_path)
		name = dir.get_next()

	dir.list_dir_end()
	return result


func _is_ignored_dir(path: String) -> bool:
	for ignore in IGNORE_DIRS:
		if path.begins_with(ignore):
			return true
	return false


func _should_skip(path: String) -> bool:
	for ignore in IGNORE_DIRS:
		if path.begins_with(ignore):
			return true
	return false
