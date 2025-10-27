class_name ParticleData

var count: int = 0
var positions: PackedVector2Array = []
var velocities: PackedVector2Array = []
var accelerations: PackedVector2Array = []
var radii: PackedFloat32Array = []
var masses: PackedFloat32Array = []

func _init() -> void:
	pass

func add_particle(position: Vector2, velocity: Vector2, radius: float, mass: float) -> void:
	assert(
		velocities.size() == count
		and radii.size() == count
		and masses.size() == count
		and accelerations.size() == count,
		"ParticleDataSyncError: particle arrays have mismatched sizes"
	)
	count += 1
	positions.append(position)
	velocities.append(velocity)
	accelerations.append(Vector2.ZERO)
	radii.append(radius)
	masses.append(mass)

func swap_buffers(new_positions: PackedVector2Array, new_velocities: PackedVector2Array, new_accelerations: PackedVector2Array) -> void:
	positions = new_positions.duplicate()
	velocities = new_velocities.duplicate()
	accelerations = new_accelerations.duplicate()
