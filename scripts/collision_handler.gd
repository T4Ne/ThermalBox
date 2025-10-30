class_name CollisionHandler
	
func _init() -> void:
	pass

func calculate_collision_movement(id: int, position: Vector2, velocity: Vector2, particles: ParticleData, cells: CellData) -> PackedVector2Array:
	var seq_particle_state: PackedVector2Array = [position, velocity]
	var cell_id: int = _cell_id_by_position(position, cells)
	_collide_with_walls(id, seq_particle_state, cell_id, particles, cells)
	#TODO: check particle collision
	return seq_particle_state

func _collide_with_particles() -> void:
	pass

func _collide_with_walls(id: int, seq_particle_state: PackedVector2Array, cell_id: int, particles: ParticleData, cells: CellData) -> void:
	var walls: PackedInt32Array = _get_neighbor_walls(cell_id, cells)
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
	var unit_surface_normal: Vector2 = surface_normal.normalized()
	seq_particle_state[0] += (unit_surface_normal * radius - surface_normal) * 2
	seq_particle_state[1] += -2 * unit_surface_normal * seq_particle_state[1].dot(unit_surface_normal) # reflect velocity with normal

func _cell_id_by_position(position: Vector2, cells: CellData) -> int:
	var cell_x: int = floori(position.x / cells.cell_size)
	var cell_y: int = floori(position.y / cells.cell_size)
	var cell_id: int = cell_x + cell_y * cells.cell_area.x
	return cell_id

func _get_neighbor_walls(cell_id: int, cells: CellData) -> PackedInt32Array:
	var cell_area: Vector2i = cells.cell_area
	
	assert(cell_id % cell_area.x > 0 and cell_id % cell_area.x < cell_area.x - 1, "NeighbourCellOutOfRangeError: Neighbour cell is out of range")
	assert(cell_id / cell_area.x > 0 and cell_id / cell_area.x < cell_area.y - 1, "NeighbourCellOutOfRangeError: Neighbour cell is out of range")
	
	var row_size: int = cells.cell_area.x
	var neighbor_ids: PackedInt32Array = [
	cell_id - 1 - row_size, cell_id - row_size, cell_id + 1 - row_size,
	cell_id - 1, cell_id, cell_id + 1,
	cell_id - 1 + row_size, cell_id + row_size, cell_id + 1 + row_size
	]
	var wall_ids: PackedInt32Array = []
	var cell_is_wall: PackedByteArray = cells.cell_is_wall
	
	for id in neighbor_ids:
		var is_wall: bool = cell_is_wall[id]
		if is_wall:
			wall_ids.append(id)
		else:
			wall_ids.append(-1)
	return wall_ids
