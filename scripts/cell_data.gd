class_name CellData

var wall_count: int = 0
var cell_size: int
var cell_area: Vector2i
var cell_count: int
var occupied_cell_count: int
var occupied_cell_ids: PackedInt32Array = []
var cell_offsets: PackedInt32Array = []
var cell_particle_indexes: PackedInt32Array = []
var cell_is_wall: PackedByteArray = []

func _init(size: int, area: Vector2i, borders: bool = true) -> void:
	cell_size = size
	cell_area = area
	cell_is_wall.resize(int(cell_area.x * cell_area.y))
	cell_count = cell_area.x * cell_area.y
	cell_offsets.resize(cell_count + 1)
	if borders:
		build_borders()

func set_cell_wall_state(indx: int, value: bool) -> void:
	cell_is_wall[indx] = int(value)

func change_wall_count_by(value: int) -> void:
	assert(wall_count + value >= 0, "WallCountValueError: Wall count cannot be smaller than 0")
	wall_count += value

func particle_mapping_reset() -> void:
	occupied_cell_ids.clear()
	cell_offsets.fill(0)
	cell_particle_indexes.clear()

func toggle_wall(coordinates: Vector2i) -> void:
	var cell_id: int = coordinates.x + cell_area.x * coordinates.y
	var is_currently_wall: int = cell_is_wall[cell_id]
	if is_currently_wall:
		cell_is_wall[cell_id] = false
		wall_count -= 1
	else:
		cell_is_wall[cell_id] = true
		wall_count += 1

func build_borders() -> void:
	var cell_area_row_size: int = cell_area.x
	for cell_indx in range(cell_count):
		if cell_indx < cell_area_row_size:
			cell_is_wall[cell_indx] = int(true)
			wall_count += 1
			continue
		elif cell_indx >= cell_count - cell_area_row_size:
			cell_is_wall[cell_indx] = int(true)
			wall_count += 1
			continue
		var cell_row_indx: int = cell_indx % cell_area_row_size
		if cell_row_indx == 0:
			cell_is_wall[cell_indx] = int(true)
			wall_count += 1
		elif cell_row_indx == cell_area_row_size - 1:
			cell_is_wall[cell_indx] = int(true)
			wall_count += 1
		else:
			cell_is_wall[cell_indx] = int(false)
