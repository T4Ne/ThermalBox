class_name CellData

var wall_count: int = 0
var cell_size: int
var cell_area: Vector2i
var cell_count: int
var occupied_cell_count: int
var occupied_cell_ids: PackedInt32Array = []
var cell_offsets: PackedInt32Array = []
var cell_particle_indexes: PackedInt32Array = []
var cell_is_wall: PackedByteArray = []
var neighbor_offsets: PackedInt32Array = []
var neighbor_cells: PackedInt32Array = []
var neighbor_range: int = 1
var neighbor_count: int = (neighbor_range*2+1)**2

func _init(size: int, area: Vector2i, borders: bool = true) -> void:
	cell_size = size
	cell_area = area
	cell_is_wall.resize(int(cell_area.x * cell_area.y))
	cell_count = cell_area.x * cell_area.y
	cell_offsets.resize(cell_count + 1)
	if borders:
		build_borders()
	_build_neighbor_offsets()

func _build_neighbor_offsets() -> void:
	neighbor_offsets.resize(cell_count + 1)
	neighbor_offsets.fill(0)
	neighbor_cells.resize(neighbor_count * cell_count)
	
	var write_index: int = 0
	for cell_id in range(cell_count):
		var neighbors: PackedInt32Array = _get_neighbor_cells(cell_id)
		for neighbor_id in neighbors:
			neighbor_cells[write_index] = neighbor_id
			write_index += 1
		neighbor_offsets[cell_id + 1] = write_index

func set_cell_wall_state(indx: int, value: bool) -> void:
	cell_is_wall[indx] = int(value)

func change_wall_count_by(value: int) -> void:
	assert(wall_count + value >= 0, "WallCountValueError: Wall count cannot be smaller than 0")
	wall_count += value

func toggle_wall(coordinates: Vector2i) -> void:
	var cell_id: int = coordinates.x + cell_area.x * coordinates.y
	var is_currently_wall: int = cell_is_wall[cell_id]
	if is_currently_wall:
		cell_is_wall[cell_id] = false
		wall_count -= 1
	else:
		cell_is_wall[cell_id] = true
		wall_count += 1

func build_borders() -> void:
	var cell_area_row_size: int = cell_area.x
	for cell_indx in range(cell_count):
		if cell_indx < cell_area_row_size:
			cell_is_wall[cell_indx] = int(true)
			wall_count += 1
			continue
		elif cell_indx >= cell_count - cell_area_row_size:
			cell_is_wall[cell_indx] = int(true)
			wall_count += 1
			continue
		var cell_row_indx: int = cell_indx % cell_area_row_size
		if cell_row_indx == 0:
			cell_is_wall[cell_indx] = int(true)
			wall_count += 1
		elif cell_row_indx == cell_area_row_size - 1:
			cell_is_wall[cell_indx] = int(true)
			wall_count += 1
		else:
			cell_is_wall[cell_indx] = int(false)

func array_coords_by_cell_id(cell_id: int) -> Vector2i:
	var cell_x: int = cell_id % cell_area.x
	var cell_y: int = cell_id / cell_area.x
	return Vector2i(cell_x, cell_y)

func cell_id_by_array_coords(coords: Vector2i) -> int:
	return int(coords.x + coords.y * cell_area.x)

func cell_id_by_pos(position: Vector2) -> int:
	var cell_x: int = floori(position.x / cell_size)
	var cell_y: int = floori(position.y / cell_size)
	assert(cell_x >= 0 and cell_x < cell_area.x, "ParticleOutOfBoundsError: Particle x-coordinate couldn't be mapped to grid.")
	assert(cell_y >= 0 and cell_y < cell_area.y, "ParticleOutOfBoundsError: Particle y-coordinate couldn't be mapped to grid.")
	var cell_id: int = cell_x + cell_y * cell_area.x
	return cell_id

func cell_pos_by_array_coords(coords: Vector2i) -> Vector2:
	var cell_x: float = float(coords.x * cell_size)
	var cell_y: float = float(coords.y * cell_size)
	return Vector2(cell_x, cell_y)

func build_cell_map(particle_count: int, particle_positions: PackedVector2Array) -> void:
	occupied_cell_ids.clear()
	cell_offsets.fill(0)
	cell_particle_indexes.clear()
	
	var non_empty_cells: int = 0
	
	# Count and determine cells of particles, also count occupied cells
	# TODO: occupied_cell_ids append is slow
	for par_indx in particle_count:
		var cell_id: int = cell_id_by_pos(particle_positions[par_indx])
		if cell_offsets[cell_id] == 0:
			non_empty_cells += 1
			occupied_cell_ids.append(cell_id)
		cell_offsets[cell_id] += 1
	occupied_cell_count = non_empty_cells
	
	# Exclusive prefix sum
	var run_sum: int = 0
	for cell_indx in range(cell_count + 1):
		var temp: int = cell_offsets[cell_indx]
		cell_offsets[cell_indx] = run_sum
		run_sum += temp
	
	if cell_particle_indexes.size() != run_sum:
		cell_particle_indexes.resize(run_sum)
	
	# Scatter pass
	var write_cursor: PackedInt32Array = PackedInt32Array(cell_offsets)
	for par_indx in range(particle_count):
		var cell_id: int = cell_id_by_pos(particle_positions[par_indx])
		var destination: int = write_cursor[cell_id]
		cell_particle_indexes[destination] = par_indx
		write_cursor[cell_id] = destination + 1

func _get_neighbor_cells(cell_id: int) -> PackedInt32Array:
	var row_size: int = cell_area.x
	var column_size: int = cell_area.y
	var cell_coords: Vector2i = array_coords_by_cell_id(cell_id)
	
	var neighbor_ids: PackedInt32Array = []
	neighbor_ids.resize(neighbor_count)
	var local_indx: int = 0
	var local_neighbor_range: Vector2i = Vector2i(-neighbor_range, neighbor_range + 1) # exclusive range
	for local_y in range(local_neighbor_range.x, local_neighbor_range.y):
		for local_x in range(local_neighbor_range.x, local_neighbor_range.y):
			var neighbor_coords: Vector2i = Vector2i(cell_coords.x + local_x, cell_coords.y + local_y)
			if neighbor_coords.x < 0 or neighbor_coords.x >= row_size:
				neighbor_ids[local_indx] = -1
			elif neighbor_coords.y < 0 or neighbor_coords.y >= column_size:
				neighbor_ids[local_indx] = -1
			else:
				neighbor_ids[local_indx] = cell_id_by_array_coords(neighbor_coords)
			local_indx += 1
	return neighbor_ids

func get_neighbors(cell_id: int) -> PackedInt32Array:
	var neighbors: PackedInt32Array = []
	neighbors.resize(neighbor_count)
	var neighbor_indx_start: int = neighbor_offsets[cell_id]
	
	for indx in range(neighbor_count):
		var neighbor_indx: int = neighbor_indx_start + indx
		var neighbor_id: int = neighbor_cells[neighbor_indx]
		neighbors[indx] = neighbor_id
	
	return neighbors

func particles_by_cells(cells: PackedInt32Array) -> PackedInt32Array:
	var neigbor_particles: PackedInt32Array = []
	
	for cell_id in cells:
		if cell_id < 0:
			continue
		var particle_indx_start: int = cell_offsets[cell_id]
		var particle_indx_end: int = cell_offsets[cell_id + 1]
		for particle_indx in range(particle_indx_start, particle_indx_end):
			var particle_id: int = cell_particle_indexes[particle_indx]
			neigbor_particles.append(particle_id)
	
	return neigbor_particles
