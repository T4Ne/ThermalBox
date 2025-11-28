class_name CollisionHandler

var interaction_range_r: float = 4.0
var interaction_range_sq: float = (interaction_range_r * Globals.default_particle_radius)**2
var wall_thermal_coef: float = 20.0
var max_force: float = Globals.max_accel
var interaction_matrix: Array = []

var cell_iteration_order: PackedInt32Array = [1, 3, 5, 7, 0, 2, 4, 6, 8]

enum InterType {LENNARD_JONES, REPULSION}


func _init() -> void:
	_build_interaction_matrix()

func _build_interaction_matrix() -> void:
	var type_count: int = 3
	interaction_matrix.resize(type_count)
	for indx in range(type_count):
		interaction_matrix[indx] = []
		interaction_matrix[indx].resize(type_count)
	
	interaction_matrix[0][0] = [-50.0, 4.0, InterType.LENNARD_JONES]
	interaction_matrix[0][1] = [-100.0, 3.5, InterType.LENNARD_JONES]
	interaction_matrix[0][2] = [-1000.0, interaction_range_r, InterType.REPULSION]
	interaction_matrix[1][0] = [-100.0, 3.5, InterType.LENNARD_JONES]
	interaction_matrix[1][1] = [-500.0, interaction_range_r, InterType.REPULSION]
	interaction_matrix[1][2] = [-50.0, 4.0, InterType.LENNARD_JONES]
	interaction_matrix[2][0] = [-1000.0, interaction_range_r, InterType.REPULSION]
	interaction_matrix[2][1] = [-50.0, 4.0, InterType.LENNARD_JONES]
	interaction_matrix[2][2] = [-500.0, interaction_range_r, InterType.REPULSION]
	
	# interactions:
	# 0-0: WEAKINTER
	# 0-1: STRONGINTER
	# 0-2: STRONGREPUL
	# 1-1: WEAKREPUL
	# 1-2: WEAKINTER
	# 2-2: WEAKREPUL

func calculate_collision_acceleration(id: int, position: Vector2, velocity: Vector2, particles: ParticleData, cells: CellData) -> Vector2:
	var combined_acceleration: Vector2 = Vector2.ZERO
	var cell_x: int = floori(position.x * cells.inverted_cell_size)
	var cell_y: int = floori(position.y * cells.inverted_cell_size)
	assert(cell_x >= 0 and cell_x < cells.cell_area.x, "ParticleOutOfBoundsError: Particle x-coordinate couldn't be mapped to grid.")
	assert(cell_y >= 0 and cell_y < cells.cell_area.y, "ParticleOutOfBoundsError: Particle y-coordinate couldn't be mapped to grid.")
	var cell_id: int = cell_x + cell_y * cells.cell_area.x
	var neighbor_count: int = cells.neighbor_count
	var neighbor_by_cell: PackedInt32Array = cells.neighbor_cells
	var neighbor_indx_start: int = cells.neighbor_offsets[cell_id]
	var neighbors: PackedInt32Array = neighbor_by_cell.slice(neighbor_indx_start, neighbor_indx_start + neighbor_count)
	
	combined_acceleration += interact_with_walls(id, position, velocity, neighbors, particles, cells)
	combined_acceleration += interact_with_particles(id, position, neighbors, particles, cells)
	return combined_acceleration

func interact_with_walls(id: int, position: Vector2, velocity: Vector2, neighbor_cells: PackedInt32Array, particles: ParticleData, cells: CellData) -> Vector2:
	var accumulated_acceleration: Vector2 = Vector2.ZERO
	var cell_side_length: float = cells.cell_size
	var mass: float = particles.masses[id]
	var wall_collision_range_sq: float = (0.45 * cell_side_length)**2
	assert(len(neighbor_cells) == 9, "NeighborCountError: Simulation doesn't support neighbor ranges over 1")
	
	
	for cell_indx in cell_iteration_order: # Check up,down,left,right squares first
		var cell_id: int = neighbor_cells[cell_indx]
		if cell_id < 0: # Is not cell
			continue
		if not cells.cell_is_wall[cell_id]: # cell is not wall
			continue
		
		var wall_array_coordinates: Vector2i = cells.array_coords_by_cell_id(cell_id)
		var wall_position: Vector2 = cells.cell_pos_by_array_coords(wall_array_coordinates)
		var wall_closest_x: float = clampf(position.x, wall_position.x, wall_position.x + cell_side_length)
		var wall_closest_y: float = clampf(position.y, wall_position.y, wall_position.y + cell_side_length)
		var wall_to_particle: Vector2 = position - Vector2(wall_closest_x, wall_closest_y)
		var distance_to_wall_squared: float = wall_to_particle.length_squared()
		
		if distance_to_wall_squared > wall_collision_range_sq: # Wall is not in range to collide
			continue
		if distance_to_wall_squared == 0.0:
			continue
		
		var wall_to_particle_unit: Vector2 = wall_to_particle.normalized()
		var wall_to_particle_distance_w: float = wall_to_particle.length() / cell_side_length
		var wall_force_magnitude: float = 1000.0 * ((0.45 / wall_to_particle_distance_w) - 1.0)
		var wall_acceleration_magnitude: float = wall_force_magnitude / mass
		var wall_acceleration: Vector2 = wall_to_particle_unit * wall_acceleration_magnitude
		
		if wall_acceleration.dot(accumulated_acceleration) > 0:
			continue
		
		var thermal_acceleration: Vector2
		var wall_type: int = cells.cell_is_wall[cell_id]
		var normal_velocity: float = velocity.dot(wall_to_particle_unit)
		match wall_type:
			1: # Normal Wall
				thermal_acceleration = Vector2.ZERO
			2: # Cold Wall
				if normal_velocity < 0:
					thermal_acceleration = Vector2.ZERO
				else:
					thermal_acceleration = -wall_thermal_coef * normal_velocity * wall_to_particle_unit
			3: # Hot Wall
				if normal_velocity < 0:
					thermal_acceleration = Vector2.ZERO
				else:
					thermal_acceleration = wall_thermal_coef * normal_velocity * wall_to_particle_unit
		
		wall_acceleration += thermal_acceleration
		accumulated_acceleration += wall_acceleration
		
	return accumulated_acceleration

func interact_with_particles(id: int, position: Vector2, neighbor_cells: PackedInt32Array, particles: ParticleData, cells: CellData) -> Vector2:
	var particle_positions: PackedVector2Array = particles.positions
	var accumulated_acceleration: Vector2 = Vector2.ZERO
	var particle_types: PackedByteArray = particles.types
	var cell_offsets: PackedInt32Array = cells.cell_offsets
	var cell_particle_indexes: PackedInt32Array = cells.cell_particle_indexes
	var radius: float = particles.radii[id]
	var mass: float = particles.radii[id]
	var type: int = particles.types[id]
	var interaction_row: Array = interaction_matrix[type]
	
	for cell_id in neighbor_cells:
		if cell_id == -1:
			continue
		
		var start_index: int = cell_offsets[cell_id]
		var end_index: int = cell_offsets[cell_id + 1]
		
		for indx in range(start_index, end_index):
			var other_id: int = cell_particle_indexes[indx]
			if id == other_id:
				continue
			var other_type: int = particle_types[other_id]
			var other_position: Vector2 = particle_positions[other_id]
			var vec_to_self: Vector2 = other_position - position
			var distance_sq: float = vec_to_self.length_squared()
			if distance_sq > interaction_range_sq:
				continue
			var uvec_to_self: Vector2 = vec_to_self.normalized()
			var dist_r: float = sqrt(distance_sq) / radius
			var params: Array = interaction_row[other_type]
			var force: float = 0.0
			if params[2] == InterType.LENNARD_JONES:
				if dist_r == 0.0:
					force = -max_force
				else:
					var b_div_d: float = params[1] / dist_r
					force = params[0]*((b_div_d)**4 - 2*(b_div_d)**2)
			else:
				if dist_r == 0.0:
					force = -max_force
				else:
					force = params[0] * ((params[1] / dist_r) - 1.0)
			force = clampf(force, -max_force, 1000.0)
			
			accumulated_acceleration += uvec_to_self * (force / mass)
	
	return accumulated_acceleration
