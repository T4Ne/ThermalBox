class_name Scheduler

var simulation: Simulation = Simulation.new()
var cells: CellData
var particles: ParticleData
var thread_count: int = 4 #TODO: pull from settings. Project settings decoupled from this value
var chunk_size: int = 100
var chunk_iterations: int
var chunks: Array = []
var time_step: float

func step(delta: float) -> void:
	time_step = delta
	_build_cell_map()
	_assign_chunks()
	var task_id: int = WorkerThreadPool.add_group_task(multi_threaded_step, chunk_iterations)
	WorkerThreadPool.wait_for_task_completion(task_id)

func multi_threaded_step(chunk_iter: int) -> void:
	var chunk: Chunk = chunks[chunk_iter]
	simulation.move_particles(time_step, particles, cells, chunk)

func _assign_chunks() -> void:
	chunks.clear()
	var current_indx: int = 0
	var end_indx: int = cells.occupied_cell_count - 1
	chunk_iterations = 0
	while current_indx <= end_indx:
		var chunk_end: int = current_indx + chunk_size - 1
		if chunk_end > end_indx:
			chunk_end = end_indx
		chunks.append(Chunk.new(current_indx, chunk_end))
		chunk_iterations += 1
		current_indx = chunk_end + 1

func set_cell_data(object: CellData) -> void:
	cells = object

func set_particle_data(object: ParticleData) -> void:
	particles = object

func _cell_id_from_pos(position: Vector2) -> int:
	var cell_x: int = floori(position.x / cells.cell_size)
	var cell_y: int = floori(position.y / cells.cell_size)
	assert(cell_x >= 0 and cell_x < cells.cell_area.x, "ParticleOutOfBoundsError: Particle x-coordinate couldn't be mapped to grid.")
	assert(cell_y >= 0 and cell_y < cells.cell_area.y, "ParticleOutOfBoundsError: Particle y-coordinate couldn't be mapped to grid.")
	var cell_id: int = cell_x + cell_y * cells.cell_area.x
	return cell_id

func _build_cell_map() -> void:
	cells.particle_mapping_reset()
	
	var count: int = particles.count
	var non_empty_cells: int = 0
	
	# Count and determine cells of particles, also count occupied cells
	for par_indx in count:
		var cell_id: int = _cell_id_from_pos(particles.positions[par_indx])
		if cells.cell_offsets[cell_id + 1] == 0:
			non_empty_cells += 1
			cells.occupied_cell_ids.append(cell_id)
		cells.cell_offsets[cell_id + 1] += 1
	cells.occupied_cell_count = non_empty_cells
	
	# Exclusive prefix sum
	var run_sum: int = 0
	for cell_indx in cells.cell_count + 1:
		var temp: int = cells.cell_offsets[cell_indx]
		cells.cell_offsets[cell_indx] = run_sum
		run_sum += temp
	if cells.cell_particle_indexes.size() != run_sum:
		cells.cell_particle_indexes.resize(run_sum)
	
	# Scatter pass
	var write_cursor: PackedInt32Array = PackedInt32Array(cells.cell_offsets)
	for par_indx in count:
		var cell_id: int = _cell_id_from_pos(particles.positions[par_indx])
		var destination: int = write_cursor[cell_id]
		cells.cell_particle_indexes[destination] = par_indx
		write_cursor[cell_id] = destination + 1
