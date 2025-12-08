class_name Scheduler

var movement_handler: MovementHandler = MovementHandler.new()
var world_state: WorldState
var chunk_size: int = 1
var min_chunk_time_usec: float = Globals.min_chunk_time_usec
var chunk_iterations: int
var chunks: Array[Chunk] = []
var time_step: float

func step(delta: float) -> void:
	if world_state.particle_count <= 0:
		return
	time_step = delta
	world_state.build_cell_map()
	_update_chunk_size()
	_assign_chunks()
	if chunk_iterations > 0:
		var group_id: int = WorkerThreadPool.add_group_task(_first_multi_threaded_step, chunk_iterations)
		WorkerThreadPool.wait_for_group_task_completion(group_id)
		_process_chunks()
		world_state.build_cell_map()
		_assign_chunks()
		group_id = WorkerThreadPool.add_group_task(_second_multi_threaded_step, chunk_iterations)
		WorkerThreadPool.wait_for_group_task_completion(group_id)
		_process_chunks()

func _first_multi_threaded_step(chunk_iter: int) -> void:
	var chunk: Chunk = chunks[chunk_iter]
	chunk.start_time = Time.get_ticks_usec()
	_prepare_chunk(chunk)
	movement_handler.first_half_verlet(time_step, world_state, chunk)
	chunk.end_time = Time.get_ticks_usec()

func _second_multi_threaded_step(chunk_iter: int) -> void:
	var chunk: Chunk = chunks[chunk_iter]
	chunk.start_time = Time.get_ticks_usec()
	_prepare_chunk(chunk)
	movement_handler.second_half_verlet(time_step, world_state, chunk)
	chunk.end_time = Time.get_ticks_usec()

func _assign_chunks() -> void:
	# TODO: chunk size and occupied cell count is known, so the Chunk array size could be initialized
	chunks.clear()
	var current_indx: int = 0
	var end_indx: int = world_state.occupied_cell_count - 1
	chunk_iterations = 0
	while current_indx <= end_indx:
		var chunk_end: int = current_indx + chunk_size - 1
		if chunk_end > end_indx:
			chunk_end = end_indx
		chunks.append(Chunk.new(current_indx, chunk_end))
		chunk_iterations += 1
		current_indx = chunk_end + 1
	#print(chunk_iterations)

func _update_chunk_size() -> void:
	if chunks.size() == 0:
		return  
	var new_chunk_size: int = chunk_size
	var time_sum: float = 0.0
	var sample_count: int = 0
	for chunk_id: int in range(chunks.size() - 1):
		var chunk: Chunk = chunks[chunk_id]
		var chunk_time: float = chunk.end_time - chunk.start_time
		if chunk_time > 0.0:
			time_sum += chunk_time
			sample_count += 1
	if sample_count == 0:
		return 
	var avg_time_usec: float = time_sum / float(sample_count)
	var chunk_time_factor: float = min_chunk_time_usec / avg_time_usec
	new_chunk_size = roundi(chunk_size * lerpf(1.0, chunk_time_factor, 0.3))
	if world_state.occupied_cell_count > 0:
		chunk_size = clampi(new_chunk_size, 1, world_state.occupied_cell_count)

func _process_chunks() -> void:
	for chunk: Chunk in chunks:
		for particle_indx: int in range(chunk.particle_count):
			var particle_id: int = chunk.particle_ids[particle_indx]
			world_state.particle_positions[particle_id] = chunk.positions[particle_indx]
			world_state.particle_velocities[particle_id] = chunk.velocities[particle_indx]
			world_state.particle_accelerations[particle_id] = chunk.accelerations[particle_indx]

func _prepare_chunk(chunk: Chunk) -> void:
	var start_cell_indx: int = chunk.cell_start
	var end_cell_indx: int = chunk.cell_end # inclusive endpoint
	var occup_cell_ids: PackedInt32Array = world_state.occupied_cell_ids
	var offsets: PackedInt32Array = world_state.cell_particle_offsets
	var cell_particle_ids: PackedInt32Array = world_state.cell_particle_ids
	var count: int = 0
	
	for occup_indx: int in range(start_cell_indx, end_cell_indx + 1):
		var cell_indx: int = occup_cell_ids[occup_indx]
		var particle_indx_start: int = offsets[cell_indx]
		var particle_indx_end: int = offsets[cell_indx + 1] # exclusive endpoint
		
		for indx: int in range(particle_indx_start, particle_indx_end):
			var particle_id: int = cell_particle_ids[indx]
			chunk.particle_ids.append(particle_id)
			count += 1
	
	chunk.particle_count = count
	chunk.resize_buffers(count)

func setup(world_state_instance: WorldState) -> void:
	world_state = world_state_instance
