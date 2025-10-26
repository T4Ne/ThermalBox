class_name CellData

var wall_count: int = 0
var cell_size: int
var cell_area: Vector2i
var cell_count: int
var cell_offsets: PackedInt32Array = []
var cell_particle_indexes: PackedInt32Array = []
var cell_is_filled: PackedByteArray = []

func _init(size: int, area: Vector2i) -> void:
	cell_size = size
	cell_area = area
	cell_is_filled.resize(int(cell_area.x * cell_area.y))
	cell_count = cell_area.x * cell_area.y
	cell_offsets.resize(cell_count + 1)

func set_cell_wall_state(indx: int, value: bool) -> void:
	cell_is_filled[indx] = int(value)

func change_wall_count_by(value: int) -> void:
	assert(wall_count + value >= 0, "WallCountValueError: Wall count cannot be smaller than 0")
	wall_count += value
