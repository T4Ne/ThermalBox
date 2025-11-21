class_name CollisionHandler

var interaction_range_r: float = 4.0
var interaction_range: float = interaction_range_r * Globals.default_particle_radius

var particle_strong_interaction_params: PackedFloat32Array = [1.0, 200.0, Globals.default_particle_radius]
var particle_weak_interaction_params: PackedFloat32Array = [1.0, 100.0, Globals.default_particle_radius]
var particle_strong_repulsion_params: PackedFloat32Array = [500.0, interaction_range_r]
var particle_weak_repulsion_params: PackedFloat32Array = [200.0, interaction_range_r]

enum InteractionParams {A, D, R}
enum RepulsionParams {A, D}
enum InteractionType {STRONGINTER, WEAKINTER, STRONGREPUL, WEAKREPUL}

func _init() -> void:
	pass

## @deprecated: Causes energy loss
func calculate_collision_movement(id: int, position: Vector2, velocity: Vector2, particles: ParticleData, cells: CellData) -> PackedVector2Array:
	var seq_particle_state: PackedVector2Array = [position, velocity]
	var cell_id: int = cells.cell_id_by_pos(position)
	var neighbor_cells: PackedInt32Array = cells.get_neighbor_cells(cell_id)
	_collide_with_particles(id, seq_particle_state, neighbor_cells, particles, cells)
	_collide_with_walls(id, seq_particle_state, neighbor_cells, particles, cells)
	return seq_particle_state

## @deprecated: Ideal particle collisions don't conserve energy
func _collide_with_particles(id: int, seq_particle_state: PackedVector2Array, neighbor_cells: PackedInt32Array, particles: ParticleData, cells: CellData) -> void:
	var neighbor_particles: PackedInt32Array = cells.particles_by_cells(neighbor_cells)
	_sequential_particle_collision(id, seq_particle_state, neighbor_particles, particles)

## @deprecated: Ideal wall collisions don't conserve energy
func _collide_with_walls(id: int, seq_particle_state: PackedVector2Array, neighbor_cells: PackedInt32Array, particles: ParticleData, cells: CellData) -> void:
	pass
	#var walls: PackedInt32Array = _walls_by_cells(neighbor_cells, cells)
	#_sequential_wall_collision(id, seq_particle_state, walls, particles, cells)

func _sequential_wall_collision(id: int, seq_particle_state: PackedVector2Array, walls: PackedInt32Array, particles: ParticleData, cells: CellData) -> void:
	var cell_side_length: int = cells.cell_size
	var radius: float = particles.radii[id]
	var cell_area: Vector2i = cells.cell_area
	
	for wall_indx in range(1, len(walls), 2): # Check up,down,left,right squares first
		var wall_id: int = walls[wall_indx]
		if wall_id < 0:
			continue
		_wall_collision(wall_id, seq_particle_state, cell_side_length, radius, cell_area)
	for wall_indx in range(0, len(walls), 2): # Check upper-left, upper-right, middle, lower-left, lower-right squares second
		var wall_id: int = walls[wall_indx]
		if wall_id < 0:
			continue
		_wall_collision(wall_id, seq_particle_state, cell_side_length, radius, cell_area)

func _sequential_particle_collision(id: int, seq_particle_state: PackedVector2Array, neighbor_particles: PackedInt32Array, particles: ParticleData) -> void:
	var radius: float = particles.radii[id]
	var mass: float = particles.masses[id]
	var max_pen: float = 0.0
	var max_pen_id: int
	var max_normal_speed: float
	var max_unit_vector: Vector2
	
	for neighbor_id in neighbor_particles:
		var neighbor_position: Vector2 = particles.positions[neighbor_id]
		var neighbor_radius: float = particles.radii[neighbor_id]
		var neighbor_velocity: Vector2 = particles.velocities[neighbor_id]
		var vector_from_neigbor: Vector2 = seq_particle_state[0] - neighbor_position
		var min_distance_squared: float = (radius + neighbor_radius)**2
		var distance_squared: float = vector_from_neigbor.length_squared()
		
		if distance_squared > min_distance_squared:
			continue
		
		var unit_vector_from_neighbor: Vector2 = vector_from_neigbor.normalized()
		var min_distance_vector: Vector2 = unit_vector_from_neighbor * radius + unit_vector_from_neighbor * neighbor_radius
		var relative_velocity: Vector2 = seq_particle_state[1] - neighbor_velocity
		var normal_speed: float = relative_velocity.dot(unit_vector_from_neighbor)
		
		if normal_speed >= 0:
			continue
		var penetration: float = (vector_from_neigbor - min_distance_vector).length()
		if penetration > max_pen:
			max_pen = penetration
			max_pen_id = neighbor_id
			max_normal_speed = normal_speed
			max_unit_vector = unit_vector_from_neighbor
	
	if max_pen_id:
		var neighbor_mass: float = particles.masses[max_pen_id]
		var step: float = max_pen / max_normal_speed
		_step(step, seq_particle_state)
		var inverse_mass_sum: float = (1.0 / mass) + (1.0 / neighbor_mass)
		var impulse_magnitude: float = -2.0 * max_normal_speed / inverse_mass_sum
		seq_particle_state[1] += (impulse_magnitude / mass) * max_unit_vector
		_step(-step, seq_particle_state)

func _wall_collision(wall_id: int, seq_particle_state: PackedVector2Array, cell_side_length: int, radius: float, cell_area: Vector2i) -> void:
	var wall_array_coordinates: Vector2i = Vector2i(wall_id % cell_area.x, wall_id / cell_area.x)
	var wall_position: Vector2 = Vector2(float(wall_array_coordinates.x * cell_side_length), float(wall_array_coordinates.y * cell_side_length))
	var wall_closest_x: float = clampf(seq_particle_state[0].x, wall_position.x, wall_position.x + cell_side_length)
	var wall_closest_y: float = clampf(seq_particle_state[0].y, wall_position.y, wall_position.y + cell_side_length)
	var distance_to_wall_squared: float = (seq_particle_state[0].x - wall_closest_x)**2 + (seq_particle_state[0].y - wall_closest_y)**2
	
	if distance_to_wall_squared > radius**2:
		return
	var wall_closest_pos: Vector2 = Vector2(wall_closest_x, wall_closest_y)
	var surface_normal: Vector2 = seq_particle_state[0] - wall_closest_pos
	
	if surface_normal == Vector2.ZERO:
		return
	var unit_surface_normal: Vector2 = surface_normal.normalized()
	var penetration: float = (unit_surface_normal * radius - surface_normal).length()
	var velocity_normal_magnitude: float = unit_surface_normal.dot(seq_particle_state[1]) # Negative towards wall
	
	if velocity_normal_magnitude >= 0:
		return
	var step: float = penetration / velocity_normal_magnitude
	_step(step, seq_particle_state) # step back
	seq_particle_state[1] += -2.0 * unit_surface_normal * seq_particle_state[1].dot(unit_surface_normal) # reflect velocity with normal
	_step(-step, seq_particle_state) # step forward

func _step(step: float, seq_particle_state: PackedVector2Array) -> void:
	seq_particle_state[0] += seq_particle_state[1] * step

func calculate_collision_acceleration(id: int, position: Vector2, velocity: Vector2, particles: ParticleData, cells: CellData) -> Vector2:
	var combined_acceleration: Vector2 = Vector2.ZERO
	var cell_id: int = cells.cell_id_by_pos(position)
	var neighbor_cells: PackedInt32Array = cells.get_neighbors(cell_id)
	var neighbor_particles: PackedInt32Array = cells.particles_by_cells(neighbor_cells)
	combined_acceleration += interact_with_walls(id, position, velocity, neighbor_cells, particles, cells)
	combined_acceleration += interact_with_particles(id, position, neighbor_particles, particles)
	return combined_acceleration

func interact_with_walls(id: int, position: Vector2, velocity: Vector2, neighbor_cells: PackedInt32Array, particles: ParticleData, cells: CellData) -> Vector2:
	var accumulated_acceleration: Vector2 = Vector2.ZERO
	var cell_side_length: float = cells.cell_size
	var mass: float = particles.masses[id]
	
	for cell_indx in range(1, len(neighbor_cells), 2): # Check up,down,left,right squares first
		var cell_id: int = neighbor_cells[cell_indx]
		accumulated_acceleration += wall_interaction(cell_id, position, accumulated_acceleration, mass, cell_side_length, cells)
	for cell_indx in range(0, len(neighbor_cells), 2): # Check upper-left, upper-right, middle, lower-left, lower-right squares second
		var cell_id: int = neighbor_cells[cell_indx]
		accumulated_acceleration += wall_interaction(cell_id, position, accumulated_acceleration, mass, cell_side_length, cells)
	
	return accumulated_acceleration

func wall_interaction(cell_id: int, position: Vector2, old_acceleration: Vector2, mass: float, cell_side_length: float, cells: CellData) -> Vector2:
	if cell_id < 0: # Is not cell
		return Vector2.ZERO
	if not cells.cell_is_wall[cell_id]: # cell is not wall
		return Vector2.ZERO
	
	var wall_array_coordinates: Vector2i = cells.array_coords_by_cell_id(cell_id)
	var wall_position: Vector2 = cells.cell_pos_by_array_coords(wall_array_coordinates)
	var wall_closest_x: float = clampf(position.x, wall_position.x, wall_position.x + cell_side_length)
	var wall_closest_y: float = clampf(position.y, wall_position.y, wall_position.y + cell_side_length)
	var wall_to_particle: Vector2 = position - Vector2(wall_closest_x, wall_closest_y)
	var distance_to_wall_squared: float = wall_to_particle.length_squared()
	
	if distance_to_wall_squared > (0.45 * cell_side_length)**2: # Wall is not in range to collide
		return Vector2.ZERO
	if distance_to_wall_squared == 0.0:
		return Vector2.ZERO
	
	var wall_to_particle_unit: Vector2 = wall_to_particle.normalized()
	var wall_to_particle_distance_w: float = wall_to_particle.length() / cell_side_length
	var wall_force_magnitude: float = 5000.0 * ((0.45 / wall_to_particle_distance_w) - 1.0)
	var wall_acceleration_magnitude: float = wall_force_magnitude / mass
	var wall_acceleration: Vector2 = wall_to_particle_unit * wall_acceleration_magnitude
	
	if wall_acceleration.dot(old_acceleration) > 0:
		return Vector2.ZERO
	
	return wall_acceleration

func interact_with_particles(id: int, position: Vector2, neighbor_particles: PackedInt32Array, particles: ParticleData) -> Vector2:
	var other_positions: PackedVector2Array = particles.positions
	var accumulated_acceleration: Vector2 = Vector2.ZERO
	var radius: float = particles.radii[id]
	var mass: float = particles.radii[id]
	var type: int = particles.types[id]
	
	for particle_id in neighbor_particles:
		if particle_id == id:
			continue
		var other_type: int = particles.types[particle_id]
		var other_position: Vector2 = other_positions[particle_id]
		var other_to_current: Vector2 = other_position - position
		
		if other_to_current.length_squared() > interaction_range**2:
			continue
		
		var other_to_current_unit: Vector2 = other_to_current.normalized()
		var dist_r: float = other_to_current.length() / radius
		var force_magnitude: float = get_force_magnitude(type, other_type, dist_r) 
		var acceleration_magnitude: float = force_magnitude / mass
		var acceleration_vector: Vector2 = other_to_current_unit * acceleration_magnitude
		accumulated_acceleration += acceleration_vector
	
	return accumulated_acceleration

func get_force_magnitude(type: int, other_type: int, distance: float) -> float:
	var interaction_type: InteractionType = get_interaction_type(type, other_type)
	var force: float
	var params: Array
	match interaction_type:
		InteractionType.STRONGINTER:
			params = particle_strong_interaction_params
			force = interaction_force(distance, params)
		InteractionType.WEAKINTER:
			params = particle_weak_interaction_params
			force = interaction_force(distance, params)
		InteractionType.STRONGREPUL:
			params = particle_strong_repulsion_params
			force = repulsion_force(distance, params)
		InteractionType.WEAKREPUL:
			params = particle_weak_repulsion_params
			force = repulsion_force(distance, params)
	return force

func interaction_force(distance: float, params: PackedFloat32Array) -> float:
	var a: float = params[InteractionParams.A]
	var d: float = params[InteractionParams.D]
	var r: float = params[InteractionParams.R]
	var force: float = 2*a*d*exp(-a*(-r+distance)) - 2*a*d*(exp(-a*(-r+distance)))**2
	return force

func repulsion_force(distance: float, params: PackedFloat32Array) -> float:
	var a: float = params[RepulsionParams.A]
	var d: float = params[RepulsionParams.D]
	var force: float = -a * ((d / (distance+0.05)) - 0.95)
	return force

func get_interaction_type(type: int, other_type: int) -> InteractionType:
	if type > other_type:
		var temp: int = type
		type = other_type
		other_type = temp
	match type:
		1:
			match other_type:
				1:
					return InteractionType.WEAKINTER
				2:
					return InteractionType.STRONGINTER
				3:
					return InteractionType.STRONGREPUL
				_:
					assert(false)
		2:
			match other_type:
				2:
					return InteractionType.WEAKREPUL
				3:
					return InteractionType.WEAKINTER
				_:
					assert(false)
		3:
			match other_type:
				3:
					return InteractionType.WEAKREPUL
				_:
					assert(false)
		_:
			assert(false)
	
	return InteractionType
