class_name Chunk

var cell_start: int = -1
var cell_end: int = -1
var particle_count: int = -1
var particle_ids: PackedInt32Array = []
var positions: PackedVector2Array = []
var velocities: PackedVector2Array = []
var accelerations: PackedVector2Array = []
var start_time: float
var end_time: float

func _init(start: int, end: int) -> void:
	cell_start = start
	cell_end = end

func resize_buffers(size: int) -> void:
	positions.resize(size)
	velocities.resize(size)
	accelerations.resize(size)
