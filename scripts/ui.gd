extends CanvasLayer

@onready var SimulationViewRect := get_node("Control/SimulationViewArea/SimulationViewRect")
@onready var SimulationViewPos := get_node("Control/SimulationViewArea/SimulationViewPos")
var simulation_view_aspect_ratio = Vector2(4.0, 3.0)
var simulation_view_size: Vector2
var simulation_view_location: Vector2
var simulation_view_scale: float
var simulation_view_edge_offset := Vector2(30, 30)


func _process(_delta: float) -> void:
	_solve_simulation_view_size()


func _solve_simulation_view_size() -> void:
	var simulation_view_area_size = SimulationViewRect.get_global_rect().size - simulation_view_edge_offset
	simulation_view_scale = min(simulation_view_area_size.x / simulation_view_aspect_ratio.x, simulation_view_area_size.y / simulation_view_aspect_ratio.y)
	simulation_view_size = Vector2(floor(simulation_view_aspect_ratio.x * simulation_view_scale), floor(simulation_view_aspect_ratio.y * simulation_view_scale))
	print(simulation_view_size)


func _solve_simulation_view_position() -> void:
	
