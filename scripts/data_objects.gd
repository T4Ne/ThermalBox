class ParticleData:
	var particle_positions: PackedVector2Array = []
	var particle_velocities: PackedVector2Array = []
	var particle_accelerations: PackedVector2Array = []
	var particle_radii: PackedFloat32Array = []
	var particle_masses: PackedFloat32Array = []
	
	func _init() -> void:
		pass


class CellData:
	var wall_count: int = 0
	var cell_size: int = 10
	var cell_area: Vector2i = Vector2i(80, 60)
	var cell_count: int
	var cell_offsets: PackedInt32Array = []
	var cell_particle_indexes: PackedInt32Array = []
	var cell_is_filled: PackedByteArray = []
	
	func _init() -> void:
		pass


class SimulationViewData:
	var simulation_view_true_size: Vector2i
	var simulation_view_size: Vector2
	var simulation_view_position: Vector2
	var simulation_view_scale: float
	var simulation_view_edge_offset := Vector2(60, 60)
	
	func _init() -> void:
		pass
