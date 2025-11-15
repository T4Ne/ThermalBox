class_name Scheduler

var simulation: Simulation = Simulation.new()
var cells: CellData
var particles: ParticleData
var chunk_size: int = 100
var chunk_iterations: int
var chunks: Array[Chunk] = []
var time_step: float

func step(delta: float) -> void:
	time_step = delta
	cells.build_cell_map(particles.count, particles.positions)
	_assign_chunks()
	if chunk_iterations > 0:
		var group_id: int = WorkerThreadPool.add_group_task(_first_multi_threaded_step, chunk_iterations)
		WorkerThreadPool.wait_for_group_task_completion(group_id)
		_apply_chunks()
		cells.build_cell_map(particles.count, particles.positions)
		_assign_chunks()
		group_id = WorkerThreadPool.add_group_task(_second_multi_threaded_step, chunk_iterations)
		WorkerThreadPool.wait_for_group_task_completion(group_id)
		_apply_chunks()

func _first_multi_threaded_step(chunk_iter: int) -> void:
	var chunk: Chunk = chunks[chunk_iter]
	simulation.first_move(time_step, particles, cells, chunk)

func _second_multi_threaded_step(chunk_iter: int) -> void:
	var chunk: Chunk = chunks[chunk_iter]
	simulation.second_move(time_step, particles, cells, chunk)

func _assign_chunks() -> void:
	# TODO: chunk size and occupied cell count is known, so the Chunk array size could be initialized
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

func _apply_chunks() -> void:
	for chunk in chunks:
		for particle_indx in range(chunk.particle_count):
			var particle_id: int = chunk.particle_indexes[particle_indx]
			particles.positions[particle_id] = chunk.positions[particle_indx]
			particles.velocities[particle_id] = chunk.velocities[particle_indx]
			particles.accelerations[particle_id] = chunk.accelerations[particle_indx]

func set_cell_data(object: CellData) -> void:
	cells = object

func set_particle_data(object: ParticleData) -> void:
	particles = object
