class_name SimulationViewData

var simulation_view_simulation_size: Vector2i
var simulation_view_screen_size: Vector2 = Vector2(0.0, 0.0)
var simulation_view_position: Vector2 = Vector2(0.0, 0.0)
var simulation_view_scale: float = 0.0
var simulation_view_edge_offset: Vector2

func _init(simulation_size: Vector2i, edge_offset: Vector2 = Vector2(60.0, 60.0)) -> void:
	simulation_view_simulation_size = simulation_size
	simulation_view_edge_offset = edge_offset

func update_simulation_view_size(view_rect_size: Vector2) -> void:
	var simulation_view_area_size: Vector2 = view_rect_size - simulation_view_edge_offset
	simulation_view_scale = min(simulation_view_area_size.x / float(simulation_view_simulation_size.x), simulation_view_area_size.y / float(simulation_view_simulation_size.y))
	simulation_view_screen_size = Vector2(float(simulation_view_simulation_size.x) * simulation_view_scale, float(simulation_view_simulation_size.y) * simulation_view_scale)

func update_simulation_view_position(view_position: Vector2) -> void:
	simulation_view_position = Vector2(view_position.x - simulation_view_screen_size.x / 2.0,
	view_position.y - simulation_view_screen_size.y / 2.0)
