class_name Simulation

var movement_handler: MovementHandler = MovementHandler.new()

func _init() -> void:
	pass

func first_move(time_step: float, world_state: WorldState, chunk: Chunk) -> void:
	_prepare_chunk(world_state, chunk)
	movement_handler.first_half_verlet(time_step, world_state, chunk)

func second_move(time_step: float, world_state: WorldState, chunk: Chunk) -> void:
	_prepare_chunk(world_state, chunk)
	movement_handler.second_half_verlet(time_step, world_state, chunk)

func _prepare_chunk(world_state: WorldState, chunk: Chunk) -> void:
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
