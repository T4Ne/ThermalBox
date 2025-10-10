class Simulation:
	var MovementHandler
	
	func _init() -> void:
		MovementHandler = preload("res://scripts/movement_handler.gd").MovementHandler.new()
		
	
	func move_particles(delta: float, particle_count: int, particle_positions: PackedVector2Array, particle_velocities: PackedVector2Array, 
	particle_accelerations: PackedVector2Array, particle_radii: PackedFloat32Array, particle_masses: PackedFloat32Array) -> void:
		
		MovementHandler.move(delta, particle_count, particle_positions, particle_velocities, 
		particle_accelerations, particle_radii, particle_masses)
