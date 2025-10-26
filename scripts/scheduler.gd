class_name Scheduler

var simulation: Simulation = Simulation.new()

func _init() -> void:
	pass

func step(delta: float, particle_data: ParticleData, cell_data: CellData) -> void:
	simulation.move_particles(delta, particle_data, cell_data)
	_build_cell_map(particle_data, cell_data)


func _cell_id_from_pos(position: Vector2, cell_data: CellData) -> int:
	var cell_x: int = floori(position.x / cell_data.cell_size)
	var cell_y: int = floori(position.y / cell_data.cell_size)
	assert(cell_x >= 0 and cell_x < cell_data.cell_area.x, "ParticleOutOfBoundsError: Particle x-coordinate couldn't be mapped to grid.")
	assert(cell_y >= 0 and cell_y < cell_data.cell_area.y, "ParticleOutOfBoundsError: Particle y-coordinate couldn't be mapped to grid.")
	var cell_id: int = cell_x + cell_y * cell_data.cell_area.x
	return cell_id

func _build_cell_map(particle_data: ParticleData, cell_data: CellData) -> void:
	cell_data.cell_offsets.fill(0)
	
	var count: int = particle_data.count
	# Count and determine cells of particles
	for par_indx in count:
		var cell_id: int = _cell_id_from_pos(particle_data.positions[par_indx], cell_data)
		cell_data.cell_offsets[cell_id + 1] += 1
	
	# Exclusive prefix sum
	var run_sum: int = 0
	for cell_indx in cell_data.cell_count + 1:
		var temp: int = cell_data.cell_offsets[cell_indx]
		cell_data.cell_offsets[cell_indx] = run_sum
		run_sum += temp
	if cell_data.cell_particle_indexes.size() != run_sum:
		cell_data.cell_particle_indexes.resize(run_sum)
	
	# Scatter pass
	var write_cursor: PackedInt32Array = PackedInt32Array(cell_data.cell_offsets)
	for par_indx in count:
		var cell_id: int = _cell_id_from_pos(particle_data.positions[par_indx], cell_data)
		var destination: int = write_cursor[cell_id]
		cell_data.cell_particle_indexes[destination] = par_indx
		write_cursor[cell_id] = destination + 1
