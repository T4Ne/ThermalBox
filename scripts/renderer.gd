class_name Renderer
extends Node2D

var mm_particles_instance: MultiMeshInstance2D = MultiMeshInstance2D.new()
var mm_particles: MultiMesh = MultiMesh.new()
var particle_quad: QuadMesh = QuadMesh.new()
var mm_walls_instance: MultiMeshInstance2D = MultiMeshInstance2D.new()
var mm_walls: MultiMesh = MultiMesh.new()
var wall_quad: QuadMesh = QuadMesh.new()
@onready var simulation_view_background: ColorRect = get_node("SimulationView")

func reinitialize_render() -> void:
	_set_up_meshes(mm_walls_instance, mm_walls, wall_quad)
	_set_up_meshes(mm_particles_instance, mm_particles, particle_quad, true)

func _set_up_meshes(mm_instance: MultiMeshInstance2D, mm: MultiMesh, quad: QuadMesh, has_particle_texture: bool = false) -> void:
	mm_instance.z_index = 3
	if self != mm_instance.get_parent():
		add_child(mm_instance)
	if has_particle_texture:
		mm_instance.texture = preload("res://resources/particle.png")
	
	quad.size = Vector2(1, 1)
	
	mm.instance_count = 0
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.mesh = quad
	
	mm_instance.multimesh = mm

func render(particles: ParticleData, cells: CellData, simulation_view: SimulationViewData) -> void:
	_render_simulation_view(simulation_view)
	_render_walls(cells, simulation_view)
	_render_particles(particles, simulation_view)

func _render_simulation_view(simulation_view: SimulationViewData) -> void:
	var simulation_view_screen_size: Vector2 = simulation_view.simulation_view_screen_size
	var simulation_view_position: Vector2 = simulation_view.simulation_view_position
	
	simulation_view_background.size = simulation_view_screen_size
	simulation_view_background.global_position = simulation_view_position

func _render_particles(particles: ParticleData, simulation_view: SimulationViewData) -> void:
	# Resize buffer if necessary
	var particle_count: int = particles.count
	if mm_particles.instance_count != particle_count:
		mm_particles.instance_count = particle_count
	var particle_positions: PackedVector2Array = particles.positions
	var particle_radii: PackedFloat32Array = particles.radii
	var simulation_view_scale: float = simulation_view.simulation_view_scale
	var simulation_view_position: Vector2 = simulation_view.simulation_view_position
	
	for particle_id in range(particle_count):
		var particle_screen_position: Vector2 = particle_positions[particle_id] * simulation_view_scale + simulation_view_position
		var particle_screen_diameter: float = particle_radii[particle_id] * 2.0 * simulation_view_scale
		var particle_transform: Transform2D = Transform2D(0.0, particle_screen_position)
		particle_transform.x = Vector2(particle_screen_diameter, 0.0)
		particle_transform.y = Vector2(0.0, particle_screen_diameter)
		
		mm_particles.set_instance_transform_2d(particle_id, particle_transform)
		var particle_type: int = particles.types[particle_id]
		match particle_type:
			0:
				mm_particles.set_instance_color(particle_id, Color("#A23A3A"))
			1:
				mm_particles.set_instance_color(particle_id, Color("#1F6B2C"))
			2:
				mm_particles.set_instance_color(particle_id, Color("#2E5D9E"))
			_:
				assert(false, "ParticleTypeError: particle has no valid type")

func _render_walls(cell_data: CellData, simulation_view: SimulationViewData) -> void:
	var wall_count: int = cell_data.wall_count
	if mm_walls.instance_count != wall_count:
		mm_walls.instance_count = wall_count
	var current_wall_indx: int = 0
	var cell_count: int = cell_data.cell_count
	var cell_is_wall: PackedByteArray = cell_data.cell_is_wall
	var cell_area: Vector2i = cell_data.cell_area
	var cell_size: int = cell_data.cell_size
	var simulation_view_position: Vector2 = simulation_view.simulation_view_position
	var simulation_view_scale: float = simulation_view.simulation_view_scale
	
	for cell_id in range(cell_count):
		if not cell_is_wall[cell_id]:
			continue
		var wall_array_coordinates: Vector2i = Vector2i(cell_id % cell_area.x, cell_id / cell_area.x)
		var wall_simulation_position: Vector2 = Vector2(float(wall_array_coordinates.x) * float(cell_size) + float(cell_size) / 2.0, 
		float(wall_array_coordinates.y) * float(cell_size) + float(cell_size) / 2.0)
		
		var wall_screen_position: Vector2 = wall_simulation_position * simulation_view_scale + simulation_view_position
		var wall_screen_size: float = simulation_view_scale * cell_size
		
		var wall_transform: Transform2D = Transform2D(0.0, wall_screen_position)
		wall_transform.x = Vector2(wall_screen_size, 0.0)
		wall_transform.y = Vector2(0.0, wall_screen_size)
		
		mm_walls.set_instance_transform_2d(current_wall_indx, wall_transform)
		var cell_wall_type: int = cell_is_wall[cell_id]
		match cell_wall_type:
			1:
				mm_walls.set_instance_color(current_wall_indx, Color("303030"))
			2:
				mm_walls.set_instance_color(current_wall_indx, Color("303080"))
			3:
				mm_walls.set_instance_color(current_wall_indx, Color("803030"))
			_:
				assert(false)
		current_wall_indx += 1
