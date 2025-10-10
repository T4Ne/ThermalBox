extends Node2D

var MM_instance: MultiMeshInstance2D
var MM: MultiMesh

func _ready() -> void:
	MM_instance = MultiMeshInstance2D.new()
	MM_instance.z_index = 1
	add_child(MM_instance)
	
	var quad := QuadMesh.new()
	quad.size = Vector2(10, 10)
	
	MM = MultiMesh.new()
	MM.transform_format = MultiMesh.TRANSFORM_2D
	MM.use_colors = true
	MM.mesh = quad
	MM.instance_count = 0
	
	MM_instance.multimesh = MM


func render(particle_count: int, particle_positions: PackedVector2Array, particle_radii: PackedFloat32Array) -> void:
	# Resize buffer if necessary
	if MM.instance_count < particle_count:
		MM.instance_count = particle_count
	
	for particle_indx in range(particle_count):
		var particle_position: Vector2 = particle_positions[particle_indx]
		var _particle_radius: float = particle_radii[particle_indx]
		var particle_transform := Transform2D(0.0, particle_position) # Rotation is zero
		#TODO: particles should scale based on the resolution of the screen
		
		MM.set_instance_transform_2d(particle_indx, particle_transform)
		MM.set_instance_color(particle_indx, Color("DARK_GREEN"))
