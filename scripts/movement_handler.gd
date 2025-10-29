class_name MovementHandler
var collision_handler: CollisionHandler = CollisionHandler.new()

func _init() -> void:
	pass

func first_half_verlet(time_step: float, particles: ParticleData, chunk: Chunk) -> void:
	var particle_count: int = chunk.particle_count
	var particle_ids: PackedInt32Array = chunk.particle_indexes
	var particle_positions: PackedVector2Array = particles.positions
	var particle_velocities: PackedVector2Array = particles.velocities
	var particle_accelerations: PackedVector2Array = particles.accelerations
	
	for particle_indx in range(particle_count):
		var particle_id: int = particle_ids[particle_indx]
		var old_position: Vector2 = particle_positions[particle_id]
		var old_velocity: Vector2 = particle_velocities[particle_id]
		var old_acceleration: Vector2 = particle_accelerations[particle_id]
		
		var half_step_velocity: Vector2 = _calculate_verlet_velocity(time_step * 0.5, old_velocity, old_acceleration)
		var predicted_full_step_position: Vector2 = _calculate_verlet_position(time_step, old_position, half_step_velocity)
		
		chunk.positions[particle_indx] = predicted_full_step_position
		chunk.velocities[particle_indx] = half_step_velocity
		chunk.accelerations[particle_indx] = old_acceleration

func second_half_verlet(time_step: float, particles: ParticleData, cells: CellData, chunk: Chunk) -> void:
	var particle_count: int = chunk.particle_count
	var particle_ids: PackedInt32Array = chunk.particle_indexes
	var particle_positions: PackedVector2Array = particles.positions
	var particle_velocities: PackedVector2Array = particles.velocities
	var particle_accelerations: PackedVector2Array = particles.accelerations
	
	for particle_indx in range(particle_count):
		var particle_id: int = particle_ids[particle_indx]
		var predicted_full_step_position: Vector2 = particle_positions[particle_id]
		var half_step_velocity: Vector2 = particle_velocities[particle_id]
		var old_acceleration: Vector2 = particle_accelerations[particle_id]
		
		collision_handler.calculate_collision(particle_id, predicted_full_step_position, half_step_velocity, particles, cells, chunk)
		var final_full_step_position: Vector2 = predicted_full_step_position # TODO: collision_handler
		var final_half_step_velocity: Vector2 = half_step_velocity # TODO: collision_handler
		var full_step_acceleration: Vector2 = _calculate_verlet_acceleration(time_step, old_acceleration)
		var full_step_velocity: Vector2 = _calculate_verlet_velocity(time_step * 0.5, final_half_step_velocity, full_step_acceleration)
		
		chunk.positions[particle_indx] = final_full_step_position
		chunk.velocities[particle_indx] = full_step_velocity
		chunk.accelerations[particle_indx] = full_step_acceleration

func _calculate_verlet_position(time_step: float, position: Vector2, velocity: Vector2) -> Vector2:
	var new_position := position + velocity * time_step
	return new_position

func _calculate_verlet_velocity(time_step: float, velocity: Vector2, acceleration: Vector2) -> Vector2:
	var new_velocity := velocity + 0.5 * acceleration * time_step
	return new_velocity

func _calculate_verlet_acceleration(_time_step:float, _acceleration: Vector2) -> Vector2:
	# TODO: gravitational acceleration should be a global variable controlled by main scene script
	var g := Vector2(0.0, 20.0)
	var new_acceleration := g
	return new_acceleration

func _calculate_force(_time_step: float, _mass: float) -> void:
	# TODO: Nearby particles apply forces to each other.
	pass
