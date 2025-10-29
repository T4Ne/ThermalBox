class_name CollisionHandler
	
func _init() -> void:
	pass

func calculate_collision(id: int, position: Vector2, _velocity: Vector2, particles: ParticleData, cells: CellData, _chunk: Chunk) -> void:
	var cell_id: int = _cell_id_by_position(position, cells)
	#TODO: check particle collision
	_collide_with_walls(id, position, cell_id, particles, cells)

func _collide_with_particles() -> void:
	pass

func _collide_with_walls(id: int, position: Vector2, cell_id: int, particles: ParticleData, cells: CellData) -> void:
	var walls: PackedInt32Array = _get_neighbor_walls(cell_id, cells)
	if not walls:
		return
	var colliding_walls: PackedInt32Array = _get_wall_collisions(id, position, walls, particles, cells)
	if not colliding_walls:
		return

func _get_wall_collisions(id: int, position: Vector2, walls: PackedInt32Array, particles: ParticleData, cells: CellData) -> PackedInt32Array:
	var cell_side_length: int = cells.cell_size
	var radius_squared: float = particles.radii[id]**2
	var cell_area: Vector2i = cells.cell_area
	var colliding: PackedInt32Array = []
	
	for wall_id in walls:
		@warning_ignore("integer_division")
		var wall_array_coordinates: Vector2i = Vector2i(wall_id % cell_area.x, wall_id / cell_area.x)
		var wall_position: Vector2 = Vector2(float(wall_array_coordinates.x * cell_side_length), float(wall_array_coordinates.y * cell_side_length))
		var wall_closest_x: float = clampf(position.x, wall_position.x, wall_position.x + cell_side_length)
		var wall_closest_y: float = clampf(position.y, wall_position.y, wall_position.y + cell_side_length)
		var distance_to_wall_squared: float = (position.x - wall_closest_x)**2 + (position.y - wall_closest_y)**2
		if distance_to_wall_squared < radius_squared:
			colliding.append(wall_id)
	
	return colliding

func _cell_id_by_position(position: Vector2, cells: CellData) -> int:
	var cell_x: int = floori(position.x / cells.cell_size)
	var cell_y: int = floori(position.y / cells.cell_size)
	var cell_id: int = cell_x + cell_y * cells.cell_area.x
	return cell_id

func _get_neighbor_walls(cell_id: int, cells: CellData) -> PackedInt32Array:
	var cell_area: Vector2i = cells.cell_area
	assert(cell_id % cell_area.x > 0 and cell_id % cell_area.x < cell_area.x - 1, "NeighbourCellOutOfRangeError: Neighbour cell is out of range")
	@warning_ignore("integer_division")
	assert(cell_id / cell_area.x > 0 and cell_id / cell_area.x < cell_area.y - 1, "NeighbourCellOutOfRangeError: Neighbour cell is out of range")
	var row_size: int = cells.cell_area.x
	var neighbor_ids: PackedInt32Array = [cell_id - 1 - row_size, cell_id - row_size, cell_id + 1 - row_size,
	cell_id - 1, cell_id + 1,
	cell_id - 1 + row_size, cell_id + row_size, cell_id + 1 + row_size]
	var wall_ids: PackedInt32Array = []
	var cell_is_wall: PackedByteArray = cells.cell_is_wall
	
	for id in neighbor_ids:
		var is_wall: bool = cell_is_wall[id]
		if is_wall:
			wall_ids.append(id)
	return wall_ids
