class_name MovementHandler
var collision_handler: CollisionHandler = CollisionHandler.new()

func _init() -> void:
	pass

func move(delta: float, particle_data: ParticleData) -> void:
	# Velocity Verlet for each particle
	var particle_count: int = particle_data.get_count()
	var particle_positions: PackedVector2Array = particle_data.get_positions()
	var particle_velocities: PackedVector2Array = particle_data.get_velocities()
	var particle_accelerations: PackedVector2Array = particle_data.get_accelerations()
	
	for particle_indx in range(particle_count):
		var position := particle_positions[particle_indx]
		var velocity := particle_velocities[particle_indx]
		var acceleration := particle_accelerations[particle_indx]
		# var _mass := particle_masses[particle_indx]
		
		var half_step_velocity := _calculate_verlet_velocity(delta * 0.5, velocity, acceleration)
		var full_step_position := _calculate_verlet_position(delta, position, half_step_velocity)
		# collision_handler.check_collisions(delta, particle_count, particle_positions, particle_velocities, particle_radii, particle_masses)
		var full_step_acceleration := _calculate_verlet_acceleration(delta, acceleration)
		var full_step_velocity := _calculate_verlet_velocity(delta * 0.5, half_step_velocity, full_step_acceleration)
		
		particle_positions[particle_indx] = full_step_position
		particle_velocities[particle_indx] = full_step_velocity
		particle_accelerations[particle_indx] = full_step_acceleration

func _calculate_verlet_position(delta: float, position: Vector2, velocity: Vector2) -> Vector2:
	var new_position := position + velocity * delta
	return new_position

func _calculate_verlet_velocity(delta: float, velocity: Vector2, acceleration: Vector2) -> Vector2:
	var new_velocity := velocity + 0.5 * acceleration * delta
	return new_velocity

func _calculate_verlet_acceleration(_delta:float, _acceleration: Vector2) -> Vector2:
	# TODO: gravitational acceleration should be a global variable controlled by main scene script
	var g := Vector2(0.0, 20.0)
	var new_acceleration := g
	return new_acceleration

func _calculate_force(_delta: float, _mass: float) -> void:
	# TODO: Nearby particles apply forces to each other.
	pass
