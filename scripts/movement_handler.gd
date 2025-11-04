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
	var _particle_accelerations: PackedVector2Array = particles.accelerations
	var particle_radii: PackedFloat32Array = particles.radii
	var particle_masses: PackedFloat32Array = particles.masses
	var gravity: Vector2 = Globals.gravity
	var gravity_is_on: bool = Globals.gravity_is_on
	
	for particle_indx in range(particle_count):
		var particle_id: int = particle_ids[particle_indx]
		var predicted_full_step_position: Vector2 = particle_positions[particle_id]
		var half_step_velocity: Vector2 = particle_velocities[particle_id]
		var radius: float = particle_radii[particle_id]
		var mass: float = particle_masses[particle_id]
		
		var collision_offsets: PackedVector2Array = collision_handler.calculate_collision_movement(particle_id, predicted_full_step_position, half_step_velocity, particles, cells)
		var final_full_step_position: Vector2 = collision_offsets[0]
		var final_half_step_velocity: Vector2 = collision_offsets[1]
		var full_step_acceleration: Vector2 = _calculate_verlet_acceleration(particle_id, final_full_step_position, radius, mass, gravity, gravity_is_on, particles)
		var full_step_velocity: Vector2 = _calculate_verlet_velocity(time_step * 0.5, final_half_step_velocity, full_step_acceleration)
		
		chunk.positions[particle_indx] = final_full_step_position
		chunk.velocities[particle_indx] = full_step_velocity
		chunk.accelerations[particle_indx] = full_step_acceleration

func _calculate_verlet_position(time_step: float, position: Vector2, velocity: Vector2) -> Vector2:
	var new_position := position + velocity * time_step
	return new_position

func _calculate_verlet_velocity(time_step: float, velocity: Vector2, acceleration: Vector2) -> Vector2:
	var new_velocity := velocity + acceleration * time_step
	return new_velocity

## @deprecated: Attraction calculation is very slow
func _calculate_verlet_acceleration(id: int, position: Vector2, radius: float, mass: float, gravity: Vector2, gravity_is_on: bool, particles: ParticleData) -> Vector2:
	var near_particles: PackedInt32Array = _find_close_particles(id, position, radius, particles)
	var other_positions: PackedVector2Array = particles.positions
	var acceleration: Vector2 = _calculate_gravity(gravity, gravity_is_on)
	for particle_id in near_particles:
		var other_position: Vector2 = other_positions[particle_id]
		var other_to_current: Vector2 = other_position - position
		var other_to_current_unit: Vector2 = other_to_current.normalized()
		var distance_r: float = other_to_current.length() / radius
		var force_magnitude: float = _calculate_force(distance_r)
		var acceleration_magnitude: float = force_magnitude / mass
		var acceleration_vector: Vector2 = other_to_current_unit * acceleration_magnitude
		acceleration += acceleration_vector
	
	return acceleration

func _calculate_gravity(gravity: Vector2, gravity_is_on: bool) -> Vector2:
	if gravity_is_on:
		return gravity
	else:
		return Vector2.ZERO

func _calculate_force(distance: float) -> float:
	var force: float = 32*distance**3 - 400*distance**2 + 1600*distance - 2000
	return force

func _find_close_particles(id: int, position: Vector2, radius: float, particles: ParticleData) -> PackedInt32Array:
	var reach_range_squared: float = (radius * 5.0)**2
	var particle_count: int = particles.count
	var positions: PackedVector2Array = particles.positions
	var close_particles: PackedInt32Array = []
	for particle_id in range(particle_count):
		if particle_id == id:
			continue
		var other_particle_position: Vector2 = positions[particle_id]
		var distance_squared: float = (other_particle_position - position).length_squared()
		if reach_range_squared < distance_squared:
			continue
		close_particles.append(particle_id)
	return close_particles
