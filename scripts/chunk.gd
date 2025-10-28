class_name Chunk

var cell_start: int
var cell_end: int
var particle_indexes: PackedInt32Array = []
var positions: PackedVector2Array = []
var velocities: PackedVector2Array = []
var accelerations: PackedVector2Array = []

func _init(start: int, end: int) -> void:
	cell_start = start
	cell_end = end
