class_name MovementHandler
var collision_handler: CollisionHandler = CollisionHandler.new()
var max_speed: float = Globals.lightspeed

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
		
		# half step velocity
		var half_step_velocity: Vector2 = old_velocity + old_acceleration * time_step * 0.5
		if half_step_velocity.length_squared() > max_speed**2:
			half_step_velocity = half_step_velocity.normalized() * max_speed
		
		# full step position
		var predicted_full_step_position: Vector2 = old_position + half_step_velocity * time_step
		
		chunk.positions[particle_indx] = predicted_full_step_position
		chunk.velocities[particle_indx] = half_step_velocity
		chunk.accelerations[particle_indx] = old_acceleration

func second_half_verlet(time_step: float, particles: ParticleData, cells: CellData, chunk: Chunk) -> void:
	var particle_count: int = chunk.particle_count
	var particle_ids: PackedInt32Array = chunk.particle_indexes
	var particle_positions: PackedVector2Array = particles.positions
	var particle_velocities: PackedVector2Array = particles.velocities
	var _particle_accelerations: PackedVector2Array = particles.accelerations
	var gravity: Vector2 = Globals.gravity
	var gravity_is_on: bool = Globals.gravity_is_on
	
	for particle_indx in range(particle_count):
		var particle_id: int = particle_ids[particle_indx]
		var predicted_full_step_position: Vector2 = particle_positions[particle_id]
		var half_step_velocity: Vector2 = particle_velocities[particle_id]
		
		var final_full_step_position: Vector2 = predicted_full_step_position 
		var final_half_step_velocity: Vector2 = half_step_velocity 
		
		# full step acceleration
		var full_step_acceleration: Vector2 = Vector2.ZERO
		if gravity_is_on:
			full_step_acceleration += gravity
		full_step_acceleration += collision_handler.calculate_collision_acceleration(particle_id, final_full_step_position, final_half_step_velocity, particles, cells)
		
		# full step velocity
		var full_step_velocity: Vector2 = final_half_step_velocity + full_step_acceleration * time_step * 0.5
		if full_step_velocity.length_squared() > max_speed**2:
			full_step_velocity = full_step_velocity.normalized() * max_speed
		
		chunk.positions[particle_indx] = final_full_step_position
		chunk.velocities[particle_indx] = full_step_velocity
		chunk.accelerations[particle_indx] = full_step_acceleration

func _calculate_verlet_position(time_step: float, position: Vector2, velocity: Vector2) -> Vector2:
	var new_position := position + velocity * time_step
	return new_position

func _calculate_verlet_velocity(time_step: float, velocity: Vector2, acceleration: Vector2) -> Vector2:
	var new_velocity: Vector2 = velocity + acceleration * time_step
	if new_velocity.length_squared() > max_speed**2:
			new_velocity = new_velocity.normalized() * max_speed
	return new_velocity

func _calculate_gravity(gravity: Vector2, gravity_is_on: bool) -> Vector2:
	if gravity_is_on:
		return gravity
	else:
		return Vector2.ZERO
