class_name Simulation

var movement_handler: MovementHandler = MovementHandler.new()

func _init() -> void:
	pass

func move_particles(delta: float, particle_data: ParticleData, cell_data: CellData) -> void:
	movement_handler.move(delta, particle_data, cell_data)
