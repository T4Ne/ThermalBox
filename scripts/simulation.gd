class_name Simulation

var movement_handler: MovementHandler = MovementHandler.new()

func _init() -> void:
	pass

func move_particles(delta: float, particles: ParticleData, cells: CellData, chunk: Chunk) -> void:
	_prepare_chunk_info(cells, chunk)
	movement_handler.move(delta, particles, cells, chunk)

func _prepare_chunk_info(cells: CellData, chunk: Chunk) -> void:
	var start_cell_indx: int = chunk.cell_start
	var end_cell_indx: int = chunk.cell_end # inclusive endpoint
	var occup_cell_ids: PackedInt32Array = cells.occupied_cell_ids
	var offsets: PackedInt32Array = cells.cell_offsets
	var cell_particle_ids: PackedInt32Array = cells.cell_particle_indexes
	
	for occup_indx in range(start_cell_indx, end_cell_indx + 1):
		var cell_indx: int = occup_cell_ids[occup_indx]
		var particle_indx_start: int = offsets[cell_indx]
		var particle_indx_end: int = offsets[cell_indx + 1] # exclusive endpoint
		
		for indx in range(particle_indx_start, particle_indx_end):
			var particle_id: int = cell_particle_ids[indx]
			chunk.particle_indexes.append(particle_id)
