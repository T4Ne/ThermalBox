extends Node2D

var mm_particles_instance: MultiMeshInstance2D
var mm_particles: MultiMesh
var particles_quad: QuadMesh
@onready var SimulationViewBackground = get_node("SimulationView")

func _ready() -> void:
	_set_up_particle_meshes()


func _set_up_particle_meshes() -> void:
	mm_particles_instance = MultiMeshInstance2D.new()
	mm_particles_instance.z_index = 3
	add_child(mm_particles_instance)
	
	particles_quad = QuadMesh.new()
	particles_quad.size = Vector2(1, 1)
	
	mm_particles = MultiMesh.new()
	mm_particles.transform_format = MultiMesh.TRANSFORM_2D
	mm_particles.use_colors = true
	mm_particles.mesh = particles_quad
	mm_particles.instance_count = 0
	
	mm_particles_instance.multimesh = mm_particles


func render(_grid_size: int, particle_count: int, particle_positions: PackedVector2Array, particle_radii: PackedFloat32Array, 
		simulation_view_size: Vector2, simulation_view_scale: float, simulation_view_location: Vector2) -> void:
	_render_simulation_view(simulation_view_size, simulation_view_location)
	_render_particles(particle_count, particle_positions, particle_radii, simulation_view_location, simulation_view_scale)


func _render_simulation_view(simulation_view_size: Vector2, simulation_view_location: Vector2) -> void:
	SimulationViewBackground.size = simulation_view_size
	SimulationViewBackground.global_position = simulation_view_location


func _render_particles(particle_count: int, particle_positions: PackedVector2Array, particle_radii: PackedFloat32Array, 
		simulation_view_location: Vector2, simulation_view_scale: float) -> void:
	# Resize buffer if necessary
	if mm_particles.instance_count < particle_count:
		mm_particles.instance_count = particle_count
	
	for particle_indx in range(particle_count):
		var particle_screen_position: Vector2 = particle_positions[particle_indx] * simulation_view_scale + simulation_view_location
		var particle_screen_diameter: float = particle_radii[particle_indx] * 2.0 * simulation_view_scale
		var particle_transform := Transform2D(0.0, particle_screen_position)
		particle_transform.x = Vector2(particle_screen_diameter, 0.0)
		particle_transform.y = Vector2(0.0, particle_screen_diameter)
		
		mm_particles.set_instance_transform_2d(particle_indx, particle_transform)
		mm_particles.set_instance_color(particle_indx, Color("DARK_GREEN"))
