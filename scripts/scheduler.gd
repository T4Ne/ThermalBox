class_name Scheduler

var simulation: Simulation = Simulation.new()

func _init() -> void:
	pass

func step(delta: float, particle_data: ParticleData, _cell_data: CellData) -> void:
	
	simulation.move_particles(delta, particle_data)
