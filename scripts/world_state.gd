class_name WorldState

var particle_count: int = 0
var particle_types: PackedByteArray = []
var particle_positions: PackedVector2Array = []
var particle_velocities: PackedVector2Array = []
var particle_accelerations: PackedVector2Array = []
var particle_radii: PackedFloat32Array = []
var particle_masses: PackedFloat32Array = []
var wall_count: int = 0
var pump_count: int = 0
var diode_count: int = 0
var spawner_count: int = 0
var cell_size: int
var cell_area: Vector2i
var cell_count: int
var occupied_cell_count: int
var occupied_cell_ids: PackedInt32Array = []
var cell_particle_offsets: PackedInt32Array = []
var cell_particle_ids: PackedInt32Array = []
var cell_types: PackedByteArray = []
var cell_neighbor_offsets: PackedInt32Array = []
var cell_neighbor_ids: PackedInt32Array = []
var neighbor_range: int = Globals.neighbor_range
var neighbor_count: int = (neighbor_range*2+1)**2
var inverted_cell_size: float
var particle_mass_by_type: PackedFloat32Array = Globals.default_particle_mass_by_type
var particle_radius: float = Globals.default_particle_radius

enum CountCategory {NONE, WALL, PUMP, DIODE, SPAWNER}
enum CellType {EMPTY, NORMWALL, COLDWALL, HOTWALL, PUMPUP, PUMPDOWN, PUMPLEFT, PUMPRIGHT, 
DIODEUP, DIODEDOWN, DIODELEFT, DIODERIGHT, SPAWNERNONE, SPAWNER1, SPAWNER2, SPAWNER3, SPAWNER4, DRAIN}
var type_category_map: Array[int] = [CountCategory.NONE, CountCategory.WALL,
CountCategory.WALL, CountCategory.WALL, CountCategory.PUMP, CountCategory.PUMP,
CountCategory.PUMP, CountCategory.PUMP, CountCategory.DIODE, CountCategory.DIODE,
CountCategory.DIODE, CountCategory.DIODE, CountCategory.SPAWNER, CountCategory.SPAWNER,
CountCategory.SPAWNER, CountCategory.SPAWNER, CountCategory.SPAWNER, CountCategory.SPAWNER]

func _init(size: int, area: Vector2i, borders: bool = true) -> void:
	cell_size = size
	inverted_cell_size = 1.0 / float(cell_size)
	cell_area = area
	cell_types.resize(int(cell_area.x * cell_area.y))
	cell_types.fill(CellType.EMPTY)
	cell_count = cell_area.x * cell_area.y
	cell_particle_offsets.resize(cell_count + 1)
	if borders:
		build_borders()
	_build_neighbor_offsets()

func _build_neighbor_offsets() -> void:
	cell_neighbor_offsets.resize(cell_count + 1)
	cell_neighbor_offsets.fill(0)
	cell_neighbor_ids.resize(neighbor_count * cell_count)
	
	var write_index: int = 0
	for cell_id: int in range(cell_count):
		var neighbors: PackedInt32Array = _get_neighbor_cells(cell_id)
		for neighbor_id: int in neighbors:
			cell_neighbor_ids[write_index] = neighbor_id
			write_index += 1
		cell_neighbor_offsets[cell_id + 1] = write_index

func set_cell_state(arr_pos: Vector2i, new_type: int) -> void:
	var cell_id: int = int(arr_pos.x + arr_pos.y * cell_area.x)
	var old_type: int = cell_types[cell_id]
	
	if old_type == new_type:
		return
	
	_update_count_by_category(type_category_map[old_type], -1)
	_update_count_by_category(type_category_map[new_type], 1)
	
	cell_types[cell_id] = new_type

func _update_count_by_category(category: int, change: int) -> void:
	match category:
		CountCategory.WALL:
			wall_count += change
		CountCategory.PUMP:
			pump_count += change
		CountCategory.DIODE:
			diode_count += change
		CountCategory.SPAWNER:
			spawner_count += change

func build_borders() -> void:
	var cell_area_row_size: int = cell_area.x
	for cell_indx: int in range(cell_count):
		if cell_indx < cell_area_row_size:
			cell_types[cell_indx] = CellType.NORMWALL
			wall_count += 1
			continue
		elif cell_indx >= cell_count - cell_area_row_size:
			cell_types[cell_indx] = CellType.NORMWALL
			wall_count += 1
			continue
		var cell_row_indx: int = cell_indx % cell_area_row_size
		if cell_row_indx == 0:
			cell_types[cell_indx] = CellType.NORMWALL
			wall_count += 1
		elif cell_row_indx == cell_area_row_size - 1:
			cell_types[cell_indx] = CellType.NORMWALL
			wall_count += 1

func build_cell_map() -> void:
	occupied_cell_ids.clear()
	cell_particle_offsets.fill(0)
	cell_particle_ids.clear()
	
	var non_empty_cells: int = 0
	
	# Count and determine cells of particles, also count occupied cells
	# TODO: occupied_cell_ids append is slow
	for par_id: int in len(particle_positions):
		var particle_pos: Vector2 = particle_positions[par_id]
		if particle_pos == Vector2(-1.0, -1.0): # particle is deleted
			continue
		var cell_x: int = floori(particle_pos.x * inverted_cell_size)
		var cell_y: int = floori(particle_pos.y * inverted_cell_size)
		if cell_x < 0 or cell_x >= cell_area.x: # particle out of bounds
			particle_count -= 1
			particle_positions[par_id] = Vector2(-1.0, -1.0)
			continue
		if cell_y < 0 or cell_y >= cell_area.y: # particle out of bounds
			particle_count -= 1
			particle_positions[par_id] = Vector2(-1.0, -1.0)
			continue
		var cell_id: int = cell_x + cell_y * cell_area.x
		if cell_types[cell_id] == CellType.DRAIN: # particle is in a drain
			particle_count -= 1
			particle_positions[par_id] = Vector2(-1.0, -1.0)
			continue
		if cell_types[cell_id] == CellType.SPAWNERNONE:
			match particle_types[par_id]:
				0:
					cell_types[cell_id] = CellType.SPAWNER1
				1:
					cell_types[cell_id] = CellType.SPAWNER2
				2:
					cell_types[cell_id] = CellType.SPAWNER3
				3:
					cell_types[cell_id] = CellType.SPAWNER4
		if cell_particle_offsets[cell_id] == 0:
			non_empty_cells += 1
			occupied_cell_ids.append(cell_id)
		cell_particle_offsets[cell_id] += 1
	occupied_cell_count = non_empty_cells
	
	# Exclusive prefix sum
	var run_sum: int = 0
	for cell_indx: int in range(cell_count + 1):
		var temp: int = cell_particle_offsets[cell_indx]
		cell_particle_offsets[cell_indx] = run_sum
		run_sum += temp
	
	if cell_particle_ids.size() != run_sum:
		cell_particle_ids.resize(run_sum)
	
	# Scatter pass
	var write_cursor: PackedInt32Array = PackedInt32Array(cell_particle_offsets)
	for par_id: int in len(particle_positions):
		var particle_pos: Vector2 = particle_positions[par_id]
		if particle_pos == Vector2(-1.0, -1.0):
			continue
		var cell_x: int = floori(particle_pos.x * inverted_cell_size)
		var cell_y: int = floori(particle_pos.y * inverted_cell_size)
		var cell_id: int = cell_x + cell_y * cell_area.x
		var destination: int = write_cursor[cell_id]
		cell_particle_ids[destination] = par_id
		write_cursor[cell_id] = destination + 1

func _get_neighbor_cells(cell_id: int) -> PackedInt32Array:
	var row_size: int = cell_area.x
	var column_size: int = cell_area.y
	var cell_x: int = cell_id % cell_area.x
	var cell_y: int = cell_id / cell_area.x
	var cell_coords: Vector2i = Vector2i(cell_x, cell_y)
	
	var neighbor_ids: PackedInt32Array = []
	neighbor_ids.resize(neighbor_count)
	var local_indx: int = 0
	var local_neighbor_range: Vector2i = Vector2i(-neighbor_range, neighbor_range + 1) # exclusive range
	for local_y: int in range(local_neighbor_range.x, local_neighbor_range.y):
		for local_x: int in range(local_neighbor_range.x, local_neighbor_range.y):
			var neighbor_coords: Vector2i = Vector2i(cell_coords.x + local_x, cell_coords.y + local_y)
			if neighbor_coords.x < 0 or neighbor_coords.x >= row_size:
				neighbor_ids[local_indx] = -1
			elif neighbor_coords.y < 0 or neighbor_coords.y >= column_size:
				neighbor_ids[local_indx] = -1
			else:
				neighbor_ids[local_indx] = int(neighbor_coords.x + neighbor_coords.y * cell_area.x)
			local_indx += 1
	return neighbor_ids

func add_particle(type: int, position: Vector2, velocity: Vector2, radius: float, mass: float) -> void:
	var id: int = particle_positions.find(Vector2(-1.0,-1.0))
	if id != -1:
		particle_count += 1
		particle_types[id] = type
		particle_positions[id] = position
		particle_velocities[id] = velocity
		particle_accelerations[id] = Vector2.ZERO
		particle_radii[id] = radius
		particle_masses[id] = mass
		return
	else:
		particle_count += 1
		particle_types.append(type)
		particle_positions.append(position)
		particle_velocities.append(velocity)
		particle_accelerations.append(Vector2.ZERO)
		particle_radii.append(radius)
		particle_masses.append(mass)
		return

func delete_particles() -> void:
	particle_count = 0
	particle_types = []
	particle_positions = []
	particle_velocities = []
	particle_accelerations = []
	particle_radii = []
	particle_masses = []

func delete_particle(id: int) -> void:
	particle_count -= 1
	particle_positions[id] = Vector2(-1.0, -1.0)

func delete_particles_by_cell(arr_pos: Vector2i) -> void:
	var cell_id: int = int(arr_pos.x + arr_pos.y * cell_area.x)
	var particles_start: int = cell_particle_offsets[cell_id]
	var particles_end: int = cell_particle_offsets[cell_id + 1]
	for particle_indx: int in range(particles_start, particles_end):
		var particle_id: int = cell_particle_ids[particle_indx]
		particle_positions[particle_id] = Vector2(-1.0,-1.0)

func spawn_particles_from_spawners() -> void:
	if spawner_count <= 0:
		return
	for cell_id: int in range(cell_count):
		var cell_type: CellType = cell_types[cell_id] as CellType
		var cell_category: CountCategory = type_category_map[cell_type] as CountCategory
		if cell_category != CountCategory.SPAWNER:
			continue
		var particle_type: int
		match cell_type:
			CellType.SPAWNER1:
				particle_type = 0
			CellType.SPAWNER2:
				particle_type = 1
			CellType.SPAWNER3:
				particle_type = 2
			CellType.SPAWNER4:
				particle_type = 3
			_:
				continue
		var particle_mass: float = particle_mass_by_type[particle_type]
		var cell_x: int = cell_id % cell_area.x
		var cell_y: int = cell_id / cell_area.x
		var cell_coords: Vector2i = Vector2i(cell_x, cell_y)
		var particle_position: Vector2 = Vector2(cell_coords.x * cell_size + cell_size * 0.5, cell_coords.y * cell_size + cell_size * 0.5)
		var particle_velocity: Vector2 = Vector2.from_angle(rad_to_deg(randf_range(0, 360))) * 5
		
		var id: int = particle_positions.find(Vector2(-1.0,-1.0))
		if id != -1:
			particle_count += 1
			particle_types[id] = particle_type
			particle_positions[id] = particle_position
			particle_velocities[id] = particle_velocity
			particle_accelerations[id] = Vector2.ZERO
			particle_radii[id] = particle_radius
			particle_masses[id] = particle_mass
		else:
			particle_count += 1
			particle_types.append(particle_type)
			particle_positions.append(particle_position)
			particle_velocities.append(particle_velocity)
			particle_accelerations.append(Vector2.ZERO)
			particle_radii.append(particle_radius)
			particle_masses.append(particle_mass)
