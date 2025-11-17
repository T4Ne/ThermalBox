class_name ParticleData

var count: int = 0
var types: PackedByteArray = []
var positions: PackedVector2Array = []
var velocities: PackedVector2Array = []
var accelerations: PackedVector2Array = []
var radii: PackedFloat32Array = []
var masses: PackedFloat32Array = []

func _init() -> void:
	pass

func add_particle(type: int, position: Vector2, velocity: Vector2, radius: float, mass: float) -> void:
	assert(
		positions.size() == count
		and velocities.size() == count
		and radii.size() == count
		and masses.size() == count
		and accelerations.size() == count
		and types.size() == count,
		"ParticleDataSyncError: particle arrays have mismatched sizes"
	)
	count += 1
	types.append(type)
	positions.append(position)
	velocities.append(velocity)
	accelerations.append(Vector2.ZERO)
	radii.append(radius)
	masses.append(mass)

func delete_particles() -> void:
	count = 0
	types = []
	positions = []
	velocities = []
	accelerations = []
	radii = []
	masses = []
