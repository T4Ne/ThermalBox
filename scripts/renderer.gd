class_name Renderer
extends Node2D

var mm_particles_instance: MultiMeshInstance2D = MultiMeshInstance2D.new()
var mm_particles: MultiMesh = MultiMesh.new()
var particle_quad: QuadMesh = QuadMesh.new()
var mm_walls_instance: MultiMeshInstance2D = MultiMeshInstance2D.new()
var mm_walls: MultiMesh = MultiMesh.new()
var wall_quad: QuadMesh = QuadMesh.new()
var mm_pumps_instace: MultiMeshInstance2D = MultiMeshInstance2D.new()
var mm_pumps: MultiMesh = MultiMesh.new()
var pump_quad: QuadMesh = QuadMesh.new()
@onready var simulation_view_background: ColorRect = get_node("SimulationView")
@onready var selected_cell: Sprite2D = get_node("SelectedCell")
@onready var previous_cell: Sprite2D = get_node("PreviousCell")
@onready var pump_texture: Texture2D = preload("res://resources/pump.png")
@onready var particle_texture: Texture2D = preload("res://resources/particle.png")
@onready var wall_texture: Texture2D = preload("res://resources/wall.png")

func reinitialize_render() -> void:
	_set_up_meshes(mm_walls_instance, mm_walls, wall_quad, wall_texture)
	_set_up_meshes(mm_particles_instance, mm_particles, particle_quad, particle_texture)
	_set_up_meshes(mm_pumps_instace, mm_pumps, pump_quad, pump_texture)

func _set_up_meshes(mm_instance: MultiMeshInstance2D, mm: MultiMesh, quad: QuadMesh, texture: Texture2D) -> void:
	mm_instance.z_index = 3
	if self != mm_instance.get_parent():
		add_child(mm_instance)
	mm_instance.texture = texture
	
	quad.size = Vector2(1, 1)
	
	mm.instance_count = 0
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.mesh = quad
	
	mm_instance.multimesh = mm

func render(world_state: WorldState, simulation_render_state: SimulationRenderState) -> void:
	_render_simulation_view(simulation_render_state)
	_render_walls(world_state, simulation_render_state)
	_render_particles(world_state, simulation_render_state)
	_render_selection(world_state, simulation_render_state)

func _render_simulation_view(simulation_view: SimulationRenderState) -> void:
	var simulation_view_screen_size: Vector2 = simulation_view.simulation_view_screen_size
	var simulation_view_position: Vector2 = simulation_view.simulation_view_position
	
	simulation_view_background.size = simulation_view_screen_size
	simulation_view_background.global_position = simulation_view_position

func _render_particles(world_state: WorldState, simulation_render_state: SimulationRenderState) -> void:
	# Resize buffer if necessary
	var particle_count: int = world_state.particle_count
	if mm_particles.instance_count != particle_count:
		mm_particles.instance_count = particle_count
	var particle_positions: PackedVector2Array = world_state.particle_positions
	var particle_radii: PackedFloat32Array = world_state.particle_radii
	var simulation_view_scale: float = simulation_render_state.simulation_view_scale
	var simulation_view_position: Vector2 = simulation_render_state.simulation_view_position
	
	for particle_id: int in range(particle_count):
		var particle_screen_position: Vector2 = particle_positions[particle_id] * simulation_view_scale + simulation_view_position
		var particle_screen_diameter: float = particle_radii[particle_id] * 2.0 * simulation_view_scale
		var particle_transform: Transform2D = Transform2D(0.0, particle_screen_position)
		particle_transform.x = Vector2(particle_screen_diameter, 0.0)
		particle_transform.y = Vector2(0.0, particle_screen_diameter)
		
		mm_particles.set_instance_transform_2d(particle_id, particle_transform)
		var particle_type: int = world_state.particle_types[particle_id]
		match particle_type:
			0:
				mm_particles.set_instance_color(particle_id, Color("#A23A3A"))
			1:
				mm_particles.set_instance_color(particle_id, Color("#1F6B2C"))
			2:
				mm_particles.set_instance_color(particle_id, Color("#2E5D9E"))
			3:
				mm_particles.set_instance_color(particle_id, Color("#555555"))
			_:
				assert(false, "ParticleTypeError: particle has no valid type")

func _render_walls(world_state: WorldState, simulation_render_state: SimulationRenderState) -> void:
	var wall_count: int = world_state.wall_count
	var pump_count: int = world_state.pump_count
	if mm_walls.instance_count != wall_count:
		mm_walls.instance_count = wall_count
	if mm_pumps.instance_count != pump_count:
		mm_pumps.instance_count = pump_count
	var current_wall_indx: int = 0
	var current_pump_indx: int = 0
	var cell_count: int = world_state.cell_count
	var cell_types: PackedByteArray = world_state.cell_types
	var cell_area: Vector2i = world_state.cell_area
	var cell_size: int = world_state.cell_size
	var simulation_view_position: Vector2 = simulation_render_state.simulation_view_position
	var simulation_view_scale: float = simulation_render_state.simulation_view_scale
	
	for cell_id: int in range(cell_count):
		if not cell_types[cell_id]:
			continue
		var cell_array_coordinates: Vector2i = Vector2i(cell_id % cell_area.x, cell_id / cell_area.x)
		var cell_simulation_position: Vector2 = Vector2(float(cell_array_coordinates.x) * float(cell_size) + float(cell_size) / 2.0, 
		float(cell_array_coordinates.y) * float(cell_size) + float(cell_size) / 2.0)
		
		var cell_screen_position: Vector2 = cell_simulation_position * simulation_view_scale + simulation_view_position
		var cell_screen_size: float = simulation_view_scale * cell_size
		
		var cell_transform: Transform2D = Transform2D(0.0, cell_screen_position)
		cell_transform.x = Vector2(cell_screen_size, 0.0)
		cell_transform.y = Vector2(0.0, cell_screen_size)
		var cell_type: int = cell_types[cell_id]
		
		if cell_type >= world_state.CellType.PUMPUP and cell_type <= world_state.CellType.PUMPRIGHT:
			match cell_type:
				world_state.CellType.PUMPUP:
					cell_transform = cell_transform * Transform2D(deg_to_rad(270), Vector2(0.0, 0.0))
				world_state.CellType.PUMPDOWN:
					cell_transform = cell_transform * Transform2D(deg_to_rad(90), Vector2(0.0, 0.0))
				world_state.CellType.PUMPLEFT:
					cell_transform = cell_transform * Transform2D(deg_to_rad(180), Vector2(0.0, 0.0))
				world_state.CellType.PUMPRIGHT:
					cell_transform = cell_transform * Transform2D(deg_to_rad(0), Vector2(0.0, 0.0))
				
			mm_pumps.set_instance_transform_2d(current_pump_indx, cell_transform)
			mm_pumps.set_instance_color(current_pump_indx, Color("bbbb00"))
			current_pump_indx += 1
		else:
			mm_walls.set_instance_transform_2d(current_wall_indx, cell_transform)
			match cell_type:
				world_state.CellType.NORMWALL:
					mm_walls.set_instance_color(current_wall_indx, Color("303030"))
				world_state.CellType.COLDWALL:
					mm_walls.set_instance_color(current_wall_indx, Color("303080"))
				world_state.CellType.HOTWALL:
					mm_walls.set_instance_color(current_wall_indx, Color("803030"))
			current_wall_indx += 1

func _render_selection(world_state: WorldState, simulation_render_state: SimulationRenderState) -> void:
	var mouse_cell_coords: Array[Vector2i] = simulation_render_state.mouse_cell_coords
	var cell_size: int = world_state.cell_size
	var sim_view_scale: float = simulation_render_state.simulation_view_scale
	var sim_view_position: Vector2 = simulation_render_state.simulation_view_position
	var iter_range: int
	match simulation_render_state.item_placement_mode:
		simulation_render_state.ItemPlacementMode.PARTICLE:
			iter_range = 0
		simulation_render_state.ItemPlacementMode.WALL:
			iter_range = 1
		simulation_render_state.ItemPlacementMode.PUMP:
			iter_range = 2
	
	for indx: int in range(iter_range):
		var cell_coords: Vector2i = mouse_cell_coords[indx]
		if cell_coords == Vector2i(-1, -1):
			if indx == 0:
				selected_cell.visible = false
			else:
				previous_cell.visible = false
			indx += 1
			continue
		if indx == 0:
			selected_cell.visible = true
		else:
			previous_cell.visible = true
		var cell_simulation_position: Vector2 = Vector2(float(cell_coords.x) * float(cell_size) + float(cell_size) / 2.0,
		float(cell_coords.y) * float(cell_size) + float(cell_size) / 2.0)
		var current_cell_screen_position: Vector2 = cell_simulation_position * sim_view_scale + sim_view_position
		var cell_screen_size: float = sim_view_scale * cell_size
		var cell_transform: Transform2D = Transform2D(0.0, current_cell_screen_position)
		cell_transform.x = Vector2(cell_screen_size / 16.0, 0.0)
		cell_transform.y = Vector2(0.0, cell_screen_size / 16.0)
		if indx == 0:
			selected_cell.global_transform = cell_transform
		else:
			previous_cell.global_transform = cell_transform
		indx += 1
