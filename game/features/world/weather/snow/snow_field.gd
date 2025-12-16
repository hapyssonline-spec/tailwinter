extends Node3D

@export var grid_size: int = 4               # 4x4 = 16 ячеек (умножится на слои)
@export var cell_size: float = 40.0          # шаг сетки
@export var height_base: float = 6.0


func _ready() -> void:
	_spawn_grid("SnowFXNear", height_base)
	_spawn_grid("SnowFXMid", height_base + 1.5)
	_spawn_grid("SnowFXFar", height_base + 3.0)


func _spawn_grid(template_node_name: String, height_offset: float) -> void:
	if grid_size <= 0:
		return

	if not has_node(template_node_name):
		return

	var template := get_node(template_node_name)
	if not (template is GPUParticles3D):
		return

	var half := float(grid_size - 1) * 0.5 * cell_size

	for gx in range(grid_size):
		for gz in range(grid_size):
			var clone := template.duplicate()
			var pos := Vector3(
				-gx * cell_size + half * 2.0 + gx * cell_size - half,
				height_offset,
				-gz * cell_size + half * 2.0 + gz * cell_size - half
			)
			clone.global_transform.origin = pos
			clone.emitting = true
			add_child(clone)
