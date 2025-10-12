extends Node2D

var mm_particles_instance: MultiMeshInstance2D
var mm_particles: MultiMesh
var particles_quad: QuadMesh
var background_instance: MeshInstance2D
var background_quad: QuadMesh

func _ready() -> void:
	_set_up_background_meshes()
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


func _set_up_background_meshes() -> void:
	background_instance = MeshInstance2D.new()
	background_instance.z_index = 2
	add_child(background_instance)
	
	background_quad = QuadMesh.new()
	background_quad.size = Vector2(1, 1)
	
	background_instance.mesh = background_quad
	

func render(grid_size: int, simulation_area: Vector2, particle_count: int, particle_positions: PackedVector2Array, 
		particle_radii: PackedFloat32Array, simulation_view_size: Vector2, simulation_view_location: Vector2) -> void:
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

func render_simulation_view(simulation_view_size: Vector2, simulation_view_location: Vector2) -> void:
	pass
	
