class Scheduler:
	var Simulation
	var Renderer
	
	
	func _init() -> void:
		Simulation = preload("res://scripts/simulation.gd").Simulation.new()
	
	
	func step(delta: float, particle_count: int, particle_positions: PackedVector2Array, 
	particle_velocities: PackedVector2Array, particle_accelerations: PackedVector2Array, 
	particle_radii: PackedFloat32Array, particle_masses: PackedFloat32Array) -> void:
		
		Simulation.move_particles(delta, particle_count, particle_positions, 
		particle_velocities, particle_accelerations, particle_radii, particle_masses)
	
