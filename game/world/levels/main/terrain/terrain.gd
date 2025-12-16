extends StaticBody3D

@export var size_x: float = 200.0
@export var size_z: float = 200.0
@export var resolution: int = 80
@export var height_amp: float = 2.5
@export var noise_freq: float = 0.05
@export var noise_seed: int = 12345
@export var flat_radius: float = 6.0
@export var flat_fade: float = 4.0

@onready var _collision: CollisionShape3D = get_node_or_null("CollisionShape3D")
@onready var _mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")

var _noise: FastNoiseLite


func _ready() -> void:
	_generate()


func _generate() -> void:
	resolution = clamp(resolution, 4, 256)
	_noise = FastNoiseLite.new()
	_noise.seed = noise_seed
	_noise.frequency = noise_freq
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN

	var verts: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	var indices: Array[int] = []

	var step_x := size_x / float(resolution)
	var step_z := size_z / float(resolution)
	var half_x := size_x * 0.5
	var half_z := size_z * 0.5

	for z in resolution + 1:
		for x in resolution + 1:
			var wx: float = -half_x + x * step_x
			var wz: float = -half_z + z * step_z
			var h: float = _height_at(wx, wz)
			verts.append(Vector3(wx, h, wz))
			uvs.append(Vector2(float(x) / resolution, float(z) / resolution))

	for z in range(resolution):
		for x in range(resolution):
			var i0 := z * (resolution + 1) + x
			var i1 := i0 + 1
			var i2 := i0 + (resolution + 1)
			var i3 := i2 + 1
			# CCW winding so normals смотрят вверх.
			indices.append_array([i0, i1, i2, i1, i3, i2])

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in indices:
		st.set_uv(uvs[i])
		st.add_vertex(verts[i])
	st.generate_normals()
	var arr_mesh := st.commit()
	if arr_mesh:
		arr_mesh.resource_local_to_scene = true

	if _mesh_instance and arr_mesh:
		_mesh_instance.mesh = arr_mesh
	_update_collision_from_mesh(arr_mesh)


func _update_collision_from_mesh(mesh: Mesh) -> void:
	if _collision == null or mesh == null:
		return
	var faces := mesh.get_faces()
	if faces.is_empty():
		return
	var shape := ConcavePolygonShape3D.new()
	shape.data = faces
	_collision.shape = shape


func get_height_at(x: float, z: float) -> float:
	return _height_at(x, z)


func _height_at(x: float, z: float) -> float:
	if _noise == null:
		return 0.0
	var h: float = _noise.get_noise_2d(x, z) * height_amp
	var dist: float = Vector2(x, z).length()
	var falloff: float = clamp((dist - flat_radius) / max(flat_fade, 0.001), 0.0, 1.0)
	return h * falloff
