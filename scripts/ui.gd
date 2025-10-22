extends CanvasLayer

@onready var SimulationViewRect := get_node("Control/SimulationViewArea/SimulationViewRect")
@onready var SimulationViewPos := get_node("Control/SimulationViewArea/SimulationViewRect/SimulationViewPos")
@onready var Renderer := get_node("ParticleRenderer")
var simulation_view_true_size: Vector2i
var simulation_view_size: Vector2
var simulation_view_position: Vector2
var simulation_view_scale: float
var simulation_view_edge_offset := Vector2(60, 60)


func _process(_delta: float) -> void:
	_update_simulation_view_info()


func _update_simulation_view_info() -> void:
	_solve_simulation_view_size()
	_solve_simulation_view_position()


func _solve_simulation_view_size() -> void:
	var simulation_view_area_size: Vector2 = SimulationViewRect.get_global_rect().size - simulation_view_edge_offset
	simulation_view_scale = min(simulation_view_area_size.x / float(simulation_view_true_size.x), simulation_view_area_size.y / float(simulation_view_true_size.y))
	simulation_view_size = Vector2(float(simulation_view_true_size.x) * simulation_view_scale, float(simulation_view_true_size.y) * simulation_view_scale)


func _solve_simulation_view_position() -> void:
	simulation_view_position = Vector2(SimulationViewPos.get_global_position().x - simulation_view_size.x / 2.0,
	SimulationViewPos.get_global_position().y - simulation_view_size.y / 2.0)


func set_sim_view_size(aspect: Vector2i) -> void:
	simulation_view_true_size = aspect


func get_simulation_view_position() -> Vector2:
	return simulation_view_position


func get_simulation_view_scale() -> float:
	return simulation_view_scale


func draw_simulation(wall_count: int, cell_count: int, cell_size: int, cell_is_filled: PackedByteArray, cell_area: Vector2i, 
particle_count: int, particle_positions: PackedVector2Array, particle_radii: PackedFloat32Array) -> void:
	Renderer.render(wall_count, cell_count, cell_size, cell_is_filled, cell_area, 
	particle_count, particle_positions, particle_radii, 
	simulation_view_size, simulation_view_scale, simulation_view_position)
