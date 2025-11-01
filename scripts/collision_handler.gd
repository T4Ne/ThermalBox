class_name CollisionHandler
	
func _init() -> void:
	pass

func calculate_collision_movement(id: int, position: Vector2, velocity: Vector2, particles: ParticleData, cells: CellData) -> PackedVector2Array:
	var seq_particle_state: PackedVector2Array = [position, velocity]
	var cell_id: int = _cell_id_by_position(position, cells)
	_collide_with_particles(id, seq_particle_state, cell_id, particles, cells)
	_collide_with_walls(id, seq_particle_state, cell_id, particles, cells)
	return seq_particle_state

func _collide_with_particles(id: int, seq_particle_state: PackedVector2Array, cell_id: int, particles: ParticleData, cells: CellData) -> void:
	var neighbor_cells: PackedInt32Array = _get_neighbor_cells(cell_id, cells)
	var neighbor_particles: PackedInt32Array = _particles_by_cells(id, neighbor_cells, cells)
	_sequential_particle_collision(id, seq_particle_state, neighbor_particles, particles)

func _collide_with_walls(id: int, seq_particle_state: PackedVector2Array, cell_id: int, particles: ParticleData, cells: CellData) -> void:
	var neighbor_cells: PackedInt32Array = _get_neighbor_cells(cell_id, cells)
	var walls: PackedInt32Array = _get_neighbor_walls(neighbor_cells, cells)
	_sequential_wall_collision(id, seq_particle_state, walls, particles, cells)

func _sequential_wall_collision(id: int, seq_particle_state: PackedVector2Array, walls: PackedInt32Array, particles: ParticleData, cells: CellData) -> void:
	var cell_side_length: int = cells.cell_size
	var radius: float = particles.radii[id]
	var cell_area: Vector2i = cells.cell_area
	
	for wall_indx in range(1, len(walls), 2): # Check up,down,left,right squares first
		var wall_id: int = walls[wall_indx]
		if wall_id < 0:
			continue
		_wall_collision(wall_id, seq_particle_state, cell_side_length, radius, cell_area)
	for wall_indx in range(0, len(walls), 2): # Check upper-left, upper-right, middle, lower-left, lower-right squares second
		var wall_id: int = walls[wall_indx]
		if wall_id < 0:
			continue
		_wall_collision(wall_id, seq_particle_state, cell_side_length, radius, cell_area)

func _sequential_particle_collision(id: int, seq_particle_state: PackedVector2Array, neighbor_particles: PackedInt32Array, particles: ParticleData) -> void:
	var radius: float = particles.radii[id]
	var mass: float = particles.masses[id]
	var max_pen: float = 0.0
	var max_pen_id: int
	var max_normal_speed: float
	var max_unit_vector: Vector2
	
	for neighbor_id in neighbor_particles:
		var neighbor_position: Vector2 = particles.positions[neighbor_id]
		var neighbor_radius: float = particles.radii[neighbor_id]
		var neighbor_velocity: Vector2 = particles.velocities[neighbor_id]
		var vector_from_neigbor: Vector2 = seq_particle_state[0] - neighbor_position
		var min_distance_squared: float = (radius + neighbor_radius)**2
		var distance_squared: float = vector_from_neigbor.length_squared()
		
		if distance_squared > min_distance_squared:
			continue
		
		var unit_vector_from_neighbor: Vector2 = vector_from_neigbor.normalized()
		var min_distance_vector: Vector2 = unit_vector_from_neighbor * radius + unit_vector_from_neighbor * neighbor_radius
		var relative_velocity: Vector2 = seq_particle_state[1] - neighbor_velocity
		var normal_speed: float = relative_velocity.dot(unit_vector_from_neighbor)
		
		if normal_speed >= 0:
			continue
		var penetration: float = (vector_from_neigbor - min_distance_vector).length()
		if penetration > max_pen:
			max_pen = penetration
			max_pen_id = neighbor_id
			max_normal_speed = normal_speed
			max_unit_vector = unit_vector_from_neighbor
	
	if max_pen_id:
		var neighbor_mass: float = particles.masses[max_pen_id]
		var step: float = max_pen / max_normal_speed
		_step(step, seq_particle_state)
		var inverse_mass_sum: float = (1.0 / mass) + (1.0 / neighbor_mass)
		var impulse_magnitude: float = -2.0 * max_normal_speed / inverse_mass_sum
		seq_particle_state[1] += (impulse_magnitude / mass) * max_unit_vector
		_step(-step, seq_particle_state)

func _wall_collision(wall_id: int, seq_particle_state: PackedVector2Array, cell_side_length: int, radius: float, cell_area: Vector2i) -> void:
	var wall_array_coordinates: Vector2i = Vector2i(wall_id % cell_area.x, wall_id / cell_area.x)
	var wall_position: Vector2 = Vector2(float(wall_array_coordinates.x * cell_side_length), float(wall_array_coordinates.y * cell_side_length))
	var wall_closest_x: float = clampf(seq_particle_state[0].x, wall_position.x, wall_position.x + cell_side_length)
	var wall_closest_y: float = clampf(seq_particle_state[0].y, wall_position.y, wall_position.y + cell_side_length)
	var distance_to_wall_squared: float = (seq_particle_state[0].x - wall_closest_x)**2 + (seq_particle_state[0].y - wall_closest_y)**2
	
	if distance_to_wall_squared > radius**2:
		return
	var wall_closest_pos: Vector2 = Vector2(wall_closest_x, wall_closest_y)
	var surface_normal: Vector2 = seq_particle_state[0] - wall_closest_pos
	
	if surface_normal == Vector2.ZERO:
		return
	var unit_surface_normal: Vector2 = surface_normal.normalized()
	var penetration: float = (unit_surface_normal * radius - surface_normal).length()
	var velocity_normal_magnitude: float = unit_surface_normal.dot(seq_particle_state[1]) # Negative towards wall
	
	if velocity_normal_magnitude >= 0:
		return
	var step: float = penetration / velocity_normal_magnitude
	_step(step, seq_particle_state) # step back
	seq_particle_state[1] += -2.0 * unit_surface_normal * seq_particle_state[1].dot(unit_surface_normal) # reflect velocity with normal
	_step(-step, seq_particle_state) # step forward

func _step(step: float, seq_particle_state: PackedVector2Array) -> void:
	seq_particle_state[0] += seq_particle_state[1] * step

func _cell_id_by_position(position: Vector2, cells: CellData) -> int:
	var cell_x: int = floori(position.x / cells.cell_size)
	var cell_y: int = floori(position.y / cells.cell_size)
	var cell_id: int = cell_x + cell_y * cells.cell_area.x
	return cell_id

func _get_neighbor_cells(cell_id: int, cells: CellData) -> PackedInt32Array:
	var cell_area: Vector2i = cells.cell_area
	
	assert(cell_id % cell_area.x > 0 and cell_id % cell_area.x < cell_area.x - 1, "NeighborCellOutOfRangeError: Neighbor cell is out of range")
	assert(cell_id / cell_area.x > 0 and cell_id / cell_area.x < cell_area.y - 1, "NeighborCellOutOfRangeError: Neighbor cell is out of range")
	
	var row_size: int = cells.cell_area.x
	var neighbor_ids: PackedInt32Array = [
	cell_id - 1 - row_size, cell_id - row_size, cell_id + 1 - row_size,
	cell_id - 1, cell_id, cell_id + 1,
	cell_id - 1 + row_size, cell_id + row_size, cell_id + 1 + row_size
	]
	return neighbor_ids

func _get_neighbor_walls(neighbor_ids: PackedInt32Array, cells: CellData) -> PackedInt32Array:
	var wall_ids: PackedInt32Array = []
	var cell_is_wall: PackedByteArray = cells.cell_is_wall
	
	for id in neighbor_ids:
		var is_wall: bool = cell_is_wall[id]
		if is_wall:
			wall_ids.append(id)
		else:
			wall_ids.append(-1)
	return wall_ids

func _particles_by_cells(id: int, neighbor_cells: PackedInt32Array, cells: CellData) -> PackedInt32Array:
	var neigbor_particles: PackedInt32Array = []
	var cell_offsets: PackedInt32Array = cells.cell_offsets
	var particles_in_cell: PackedInt32Array = cells.cell_particle_indexes
	
	for cell_id in neighbor_cells:
		var particle_indx_start: int = cell_offsets[cell_id]
		var particle_indx_end: int = cell_offsets[cell_id + 1]
		for particle_indx in range(particle_indx_start, particle_indx_end):
			var particle_id: int = particles_in_cell[particle_indx]
			if particle_id == id:
				continue
			neigbor_particles.append(particle_id)
	
	return neigbor_particles
