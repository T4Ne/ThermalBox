class_name SimulationRenderState

var simulation_view_simulation_size: Vector2i
var simulation_view_screen_size: Vector2 = Vector2(0.0, 0.0)
var simulation_view_position: Vector2 = Vector2(0.0, 0.0)
var simulation_view_scale: float = 0.0
var simulation_view_edge_offset: Vector2
var mouse_sim_position: Vector2 = Vector2(-1, -1)
var mouse_cell_coords: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(-1, -1)]
var item_placement_mode: ItemPlacementMode
var extended_range: bool = false

enum ItemPlacementMode {PARTICLEDELETE, PARTICLE, WALL, PUMP, TEMPCHANGE}

func _init() -> void:
	pass

func reset(simulation_size: Vector2i, edge_offset: Vector2 = Vector2(60.0, 60.0)) -> void:
	simulation_view_simulation_size = simulation_size
	simulation_view_edge_offset = edge_offset

func update_simulation_view_size(view_rect_size: Vector2) -> void:
	var simulation_view_area_size: Vector2 = view_rect_size - simulation_view_edge_offset
	simulation_view_scale = min(simulation_view_area_size.x / float(simulation_view_simulation_size.x), simulation_view_area_size.y / float(simulation_view_simulation_size.y))
	simulation_view_screen_size = Vector2(float(simulation_view_simulation_size.x) * simulation_view_scale, float(simulation_view_simulation_size.y) * simulation_view_scale)

func update_simulation_view_position(view_position: Vector2) -> void:
	simulation_view_position = Vector2(view_position.x - simulation_view_screen_size.x / 2.0,
	view_position.y - simulation_view_screen_size.y / 2.0)

func update_mouse_cell_coords(global_mouse_position: Vector2, cell_size: float) -> void:
	
	if global_mouse_position.x < simulation_view_position.x or global_mouse_position.x >= simulation_view_position.x + simulation_view_screen_size.x:
		mouse_cell_coords = [Vector2(-1, -1), Vector2(-1, -1)]
		mouse_sim_position = Vector2(-1, -1)
		return
	if global_mouse_position.y < simulation_view_position.y or global_mouse_position.y >= simulation_view_position.y + simulation_view_screen_size.y:
		mouse_cell_coords = [Vector2(-1, -1), Vector2(-1, -1)]
		mouse_sim_position = Vector2(-1, -1)
		return
	var mouse_sim_x: float = (global_mouse_position.x - simulation_view_position.x) / simulation_view_scale
	var mouse_sim_y: float = (global_mouse_position.y - simulation_view_position.y) / simulation_view_scale
	mouse_sim_position = Vector2(mouse_sim_x, mouse_sim_y)
	var cell_x: int = int(mouse_sim_x / cell_size)
	var cell_y: int = int(mouse_sim_y / cell_size)
	var new_cell_coords: Vector2i = Vector2i(cell_x, cell_y)
	if new_cell_coords == mouse_cell_coords[0]:
		return
	else:
		if new_cell_coords.x == mouse_cell_coords[0].x or new_cell_coords.y == mouse_cell_coords[0].y:
			mouse_cell_coords[1] = mouse_cell_coords[0]
		else:
			mouse_cell_coords[1] = Vector2i(-1, -1)
		mouse_cell_coords[0] = new_cell_coords
