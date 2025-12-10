class_name MovementHandler

var max_speed: float = Globals.lightspeed
var max_speed_sq: float = max_speed ** 2
var interaction_range_r: float = Globals.interaction_range_r
var interaction_range_sq: float = (interaction_range_r * Globals.default_particle_radius)**2
var wall_thermal_coef: float = Globals.wall_thermal_coef
var wall_thermal_coef_inv: float = 1.0 / wall_thermal_coef
var pump_acceleration: float = Globals.pump_acceleration
var pump_max_speed: float = Globals.pump_max_speed
var max_acceleration: float = Globals.max_accel
var interaction_matrix: Array[Array] = []
var cell_iteration_order: PackedInt32Array = [1, 3, 5, 7, 0, 2, 4, 6, 8]
var gravity_is_on: bool = Globals.gravity_is_on
var gravity: Vector2 = Globals.gravity


enum InterType {LENNARD_JONES, REPULSION}

func _init() -> void:
	_build_interaction_matrix()

func _build_interaction_matrix() -> void:
	var type_count: int = 4
	interaction_matrix.resize(type_count)
	for indx: int in range(type_count):
		interaction_matrix[indx] = []
		interaction_matrix[indx].resize(type_count)
	
	interaction_matrix[0][0] = [Globals.weak_lennard[0], Globals.weak_lennard[1], InterType.LENNARD_JONES]
	interaction_matrix[0][1] = [Globals.strong_lennard[0], Globals.strong_lennard[1], InterType.LENNARD_JONES]
	interaction_matrix[0][2] = [Globals.weak_lennard[0], Globals.weak_lennard[1], InterType.LENNARD_JONES]
	interaction_matrix[0][3] = [Globals.weak_repul[0], Globals.weak_repul[1], InterType.REPULSION]
	interaction_matrix[1][0] = [Globals.strong_lennard[0], Globals.strong_lennard[1], InterType.LENNARD_JONES]
	interaction_matrix[1][1] = [Globals.strong_repul[0], Globals.strong_repul[1], InterType.REPULSION]
	interaction_matrix[1][2] = [Globals.weak_repul[0], Globals.weak_repul[1], InterType.REPULSION]
	interaction_matrix[1][3] = [Globals.weak_repul[0], Globals.weak_repul[1], InterType.REPULSION]
	interaction_matrix[2][0] = [Globals.weak_lennard[0], Globals.weak_lennard[1], InterType.LENNARD_JONES]
	interaction_matrix[2][1] = [Globals.weak_repul[0], Globals.weak_repul[1], InterType.REPULSION]
	interaction_matrix[2][2] = [Globals.weak_repul[0], Globals.weak_repul[1], InterType.REPULSION]
	interaction_matrix[2][3] = [Globals.weak_repul[0], Globals.weak_repul[1], InterType.REPULSION]
	interaction_matrix[3][0] = [Globals.weak_repul[0], Globals.weak_repul[1], InterType.REPULSION]
	interaction_matrix[3][1] = [Globals.weak_repul[0], Globals.weak_repul[1], InterType.REPULSION]
	interaction_matrix[3][2] = [Globals.weak_repul[0], Globals.weak_repul[1], InterType.REPULSION]
	interaction_matrix[3][3] = [Globals.weak_repul[0], Globals.weak_repul[1], InterType.REPULSION]
	
	# interactions:
	# 0-0: WEAKINTER
	# 0-1: STRONGINTER
	# 0-2: WEAKINTER
	# 0-3: WEAKREPUL
	# 1-1: STRONGREPUL
	# 1-2: WEAKREPUL
	# 1-3: WEAKREPUL
	# 2-2: WEAKREPUL
	# 2-3: WEAKREPUL
	# 3-3: WEAKREPUL

func first_half_verlet(time_step: float, world_state: WorldState, chunk: Chunk) -> void:
	var particle_count: int = chunk.particle_count
	var particle_ids: PackedInt32Array = chunk.particle_ids
	var particle_positions: PackedVector2Array = world_state.particle_positions
	var particle_velocities: PackedVector2Array = world_state.particle_velocities
	var particle_accelerations: PackedVector2Array = world_state.particle_accelerations
	
	for particle_indx: int in range(particle_count):
		var particle_id: int = particle_ids[particle_indx]
		var old_position: Vector2 = particle_positions[particle_id]
		var old_velocity: Vector2 = particle_velocities[particle_id]
		var old_acceleration: Vector2 = particle_accelerations[particle_id]
		
		# half step velocity
		var half_step_velocity: Vector2 = old_velocity + old_acceleration * time_step * 0.5
		if half_step_velocity.length_squared() > max_speed_sq:
			half_step_velocity = half_step_velocity.normalized() * max_speed
		
		# full step position
		var predicted_full_step_position: Vector2 = old_position + half_step_velocity * time_step
		
		chunk.positions[particle_indx] = predicted_full_step_position
		chunk.velocities[particle_indx] = half_step_velocity
		chunk.accelerations[particle_indx] = old_acceleration

func second_half_verlet(time_step: float, world_state: WorldState, chunk: Chunk) -> void:
	var particle_count: int = chunk.particle_count
	var particle_ids: PackedInt32Array = chunk.particle_ids
	var particle_positions: PackedVector2Array = world_state.particle_positions
	var particle_velocities: PackedVector2Array = world_state.particle_velocities
	var _particle_accelerations: PackedVector2Array = world_state.particle_accelerations
	
	for particle_indx: int in range(particle_count):
		var particle_id: int = particle_ids[particle_indx]
		var predicted_full_step_position: Vector2 = particle_positions[particle_id]
		var predicted_half_step_velocity: Vector2 = particle_velocities[particle_id]
		
		# full step acceleration
		var full_step_acceleration: Vector2 = Vector2.ZERO
		var final_full_step_position: Vector2
		var final_half_step_velocity: Vector2
		var values: PackedVector2Array = _calculate_collisions(time_step, particle_id, predicted_full_step_position, predicted_half_step_velocity, world_state)
		final_full_step_position = values[1]
		final_half_step_velocity = predicted_half_step_velocity #values[2]
		full_step_acceleration += values[0]
		
		if full_step_acceleration.length_squared() > max_acceleration**2:
			full_step_acceleration = full_step_acceleration.normalized() * max_acceleration
		
		# full step velocity
		var full_step_velocity: Vector2 = final_half_step_velocity + full_step_acceleration * time_step * 0.5
		if full_step_velocity.length_squared() > max_speed**2:
			full_step_velocity = full_step_velocity.normalized() * max_speed
		
		chunk.positions[particle_indx] = final_full_step_position
		chunk.velocities[particle_indx] = full_step_velocity
		chunk.accelerations[particle_indx] = full_step_acceleration

func _interact_with_particles(id: int, position: Vector2, neighbor_cells: PackedInt32Array, world_state: WorldState) -> Vector2:
	var particle_positions: PackedVector2Array = world_state.particle_positions
	var accumulated_acceleration: Vector2 = Vector2.ZERO
	var particle_types: PackedByteArray = world_state.particle_types
	var cell_offsets: PackedInt32Array = world_state.cell_particle_offsets
	var cell_particle_indexes: PackedInt32Array = world_state.cell_particle_ids
	var radius: float = world_state.particle_radii[id]
	var mass: float = world_state.particle_masses[id]
	var type: int = world_state.particle_types[id]
	var interaction_row: Array = interaction_matrix[type]
	
	for cell_id: int in neighbor_cells:
		if cell_id == -1:
			continue
		
		var start_index: int = cell_offsets[cell_id]
		var end_index: int = cell_offsets[cell_id + 1]
		
		for indx: int in range(start_index, end_index):
			var other_id: int = cell_particle_indexes[indx]
			if id == other_id:
				continue
			var other_type: int = particle_types[other_id]
			var other_position: Vector2 = particle_positions[other_id]
			var vec_to_self: Vector2 = other_position - position
			var distance_sq: float = vec_to_self.length_squared()
			if distance_sq > interaction_range_sq:
				continue
			var uvec_to_self: Vector2 = vec_to_self.normalized()
			var dist_r: float = sqrt(distance_sq) / radius
			var params: Array = interaction_row[other_type]
			var force: float = 0.0
			if params[2] == InterType.LENNARD_JONES:
				if dist_r == 0.0:
					force = -max_acceleration * mass
				else:
					var b_div_d: float = params[1] / dist_r
					force = params[0]*((b_div_d)**4 - 2*(b_div_d)**2)
			else:
				if dist_r == 0.0:
					force = -max_acceleration * mass
				else:
					force = params[0] * ((params[1] / dist_r) - 1.0)
			
			accumulated_acceleration += uvec_to_self * (force / mass)
	
	if accumulated_acceleration.length_squared() > max_acceleration**2:
			accumulated_acceleration = accumulated_acceleration.normalized() * max_acceleration
	return accumulated_acceleration

func _collide_with_walls(time_step: float, id: int, position: Vector2, velocity: Vector2, neighbor_cells: PackedInt32Array, world_state: WorldState) -> PackedVector2Array:
	var accumulated_acceleration: Vector2 = Vector2.ZERO
	var sequential_velocity: Vector2 = velocity
	var sequential_position: Vector2 = position
	var cell_side_length: float = world_state.cell_size
	var particle_radius: float = world_state.particle_radii[id] * 1.2
	var particle_radius_sq: float = particle_radius ** 2
	var cell_types: PackedByteArray = world_state.cell_types
	var cell_area: Vector2i = world_state.cell_area
	var count_category_map: Array = world_state.type_category_map
	var was_in_pump: bool = false
	assert(len(neighbor_cells) == 9, "NeighborCountError: Simulation doesn't support neighbor ranges over 1")

	for cell_indx: int in cell_iteration_order: # Check up,down,left,right squares first
		var cell_id: int = neighbor_cells[cell_indx]
		var cell_type: int = cell_types[cell_id]
		if cell_id < 0: # Is not cell
			continue
		if not cell_type: # cell is not a valid item
			continue
		
		var cell_x: float = (float(cell_id % cell_area.x)) * cell_side_length
		var cell_y: float = (float(cell_id / cell_area.x)) * cell_side_length
		var wall_position: Vector2 = Vector2(cell_x, cell_y)
		var wall_closest_x: float = clampf(sequential_position.x, wall_position.x, wall_position.x + cell_side_length)
		var wall_closest_y: float = clampf(sequential_position.y, wall_position.y, wall_position.y + cell_side_length)
		var wall_to_particle: Vector2 = sequential_position - Vector2(wall_closest_x, wall_closest_y)
		var distance_to_wall_squared: float = wall_to_particle.length_squared()
		
		if distance_to_wall_squared > particle_radius_sq: # Wall is not in range to collide
			continue
		
		var cell_category: int = count_category_map[cell_type]
		
		if cell_category == 3: # Cell is a diode
			if distance_to_wall_squared == 0.0: # Particle is inside wall
				continue
			var diode_direction: Vector2
			match cell_type:
				8: # diode up
					diode_direction = Vector2(0, -1)
				9: # diode down
					diode_direction = Vector2(0, 1)
				10: # diode left
					diode_direction = Vector2(-1, 0)
				11: # diode right
					diode_direction = Vector2(1, 0)
			if wall_to_particle.dot(diode_direction) <= 0.0:
				continue
			var wall_to_particle_unit: Vector2 = wall_to_particle.normalized()
			var normal_velocity_mag: float = wall_to_particle_unit.dot(sequential_velocity)
			if normal_velocity_mag > 0:
				continue
			var penetration: float = particle_radius - sqrt(distance_to_wall_squared)
			sequential_position += wall_to_particle_unit * penetration
			accumulated_acceleration += -2 * (normal_velocity_mag / time_step) * wall_to_particle_unit
		
		elif cell_category == 2: # Cell is a pump
			if distance_to_wall_squared != 0.0:
				continue
			var pump_direction: Vector2
			match cell_type:
				4: # pump up
					pump_direction = Vector2(0, -1)
				5: # pump down
					pump_direction = Vector2(0, 1)
				6: # pump left
					pump_direction = Vector2(-1, 0)
				7: # pump right
					pump_direction = Vector2(1, 0)
			var pump_direction_velocity: float = pump_direction.dot(sequential_velocity)
			if pump_direction_velocity < pump_max_speed:
				accumulated_acceleration += pump_direction * pump_acceleration
			was_in_pump = true
		
		elif cell_category == 1:
			if distance_to_wall_squared == 0.0: # Particle is inside wall
				continue
			var wall_to_particle_unit: Vector2 = wall_to_particle.normalized()
			var normal_velocity_mag: float = wall_to_particle_unit.dot(sequential_velocity)
			if normal_velocity_mag > 0:
				continue
			var penetration: float = particle_radius - sqrt(distance_to_wall_squared)
			sequential_position += wall_to_particle_unit * penetration
			var wall_type: int = world_state.cell_types[cell_id]
			match wall_type:
				1: # norm wall
					accumulated_acceleration += -2 * (normal_velocity_mag / time_step) * wall_to_particle_unit
				2: # cold wall
					accumulated_acceleration += -2 * (normal_velocity_mag / time_step) * wall_to_particle_unit * wall_thermal_coef
				3: # hot wall
					accumulated_acceleration += -2 * (normal_velocity_mag / time_step) * wall_to_particle_unit * wall_thermal_coef_inv
	
	if gravity_is_on and not was_in_pump:
		accumulated_acceleration += gravity
	var values: PackedVector2Array = [accumulated_acceleration, sequential_position, sequential_velocity]
	return values

func _calculate_collisions(time_step: float, id: int, position: Vector2, velocity: Vector2, world_state: WorldState) -> PackedVector2Array:
	var combined_acceleration: Vector2 = Vector2.ZERO
	var cell_x: int = floori(position.x * world_state.inverted_cell_size)
	var cell_y: int = floori(position.y * world_state.inverted_cell_size)
	assert(cell_x >= 0 and cell_x < world_state.cell_area.x, "ParticleOutOfBoundsError: Particle x-coordinate couldn't be mapped to grid.")
	assert(cell_y >= 0 and cell_y < world_state.cell_area.y, "ParticleOutOfBoundsError: Particle y-coordinate couldn't be mapped to grid.")
	var cell_id: int = cell_x + cell_y * world_state.cell_area.x
	var neighbor_count: int = world_state.neighbor_count
	var neighbor_by_cell: PackedInt32Array = world_state.cell_neighbor_ids
	var neighbor_indx_start: int = world_state.cell_neighbor_offsets[cell_id]
	var neighbors: PackedInt32Array = neighbor_by_cell.slice(neighbor_indx_start, neighbor_indx_start + neighbor_count)
	var values: PackedVector2Array = _collide_with_walls(time_step, id, position, velocity, neighbors, world_state)
	var new_position: Vector2 = values[1]
	var new_velocity: Vector2 = values[2]
	combined_acceleration += values[0]
	combined_acceleration += _interact_with_particles(id, position, neighbors, world_state)
	var data: PackedVector2Array = [combined_acceleration, new_position, new_velocity]
	return data
