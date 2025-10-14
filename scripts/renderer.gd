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
	particles_quad.size = Vector2(10, 10)
	
	mm_particles = MultiMesh.new()
	mm_particles.transform_format = MultiMesh.TRANSFORM_2D
	mm_particles.use_colors = true
	mm_particles.mesh = particles_quad
	mm_particles.instance_count = 0
	
	mm_particles_instance.multimesh = mm_particles



func render(grid_size: int, simulation_area: Vector2, particle_count: int, particle_positions: PackedVector2Array, 
		particle_radii: PackedFloat32Array, simulation_view_size: Vector2, simulation_view_location: Vector2) -> void:
	_render_simulation_view(simulation_view_size, simulation_view_location)
	_render_particles(particle_count, particle_positions, particle_radii)


func _render_simulation_view(simulation_view_size: Vector2, simulation_view_location: Vector2) -> void:
	SimulationViewBackground.size = simulation_view_size
	SimulationViewBackground.global_position = simulation_view_location


func _render_particles(particle_count: int, particle_positions: PackedVector2Array, particle_radii: PackedFloat32Array) -> void:
	# Resize buffer if necessary
	if mm_particles.instance_count < particle_count:
		mm_particles.instance_count = particle_count
	
	for particle_indx in range(particle_count):
		var particle_position: Vector2 = particle_positions[particle_indx]
		var particle_radius: float = particle_radii[particle_indx]
		var particle_transform := Transform2D(0.0, particle_position) #scaled(Vector2(particle_radius, particle_radius)) # Rotation is zero
		#TODO: particles should scale based on the resolution of the screen
		
		#TODO: fix particle scaling issue
		mm_particles.set_instance_transform_2d(particle_indx, particle_transform)
		mm_particles.set_instance_color(particle_indx, Color("DARK_GREEN"))
