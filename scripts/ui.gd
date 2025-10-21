extends CanvasLayer

@onready var SimulationViewRect := get_node("Control/SimulationViewArea/SimulationViewRect")
@onready var SimulationViewPos := get_node("Control/SimulationViewArea/SimulationViewRect/SimulationViewPos")
@onready var Renderer := get_node("ParticleRenderer")
var simulation_view_true_size
var simulation_view_size: Vector2
var simulation_view_location: Vector2
var simulation_view_scale: float
var simulation_view_edge_offset := Vector2(60, 60)


func _process(_delta: float) -> void:
	_update_simulation_view_info()


func _update_simulation_view_info() -> void:
	_solve_simulation_view_size()
	_solve_simulation_view_position()


func _solve_simulation_view_size() -> void:
	var simulation_view_area_size = SimulationViewRect.get_global_rect().size - simulation_view_edge_offset
	simulation_view_scale = min(simulation_view_area_size.x / simulation_view_true_size.x, simulation_view_area_size.y / simulation_view_true_size.y)
	simulation_view_size = Vector2(floor(simulation_view_true_size.x * simulation_view_scale), floor(simulation_view_true_size.y * simulation_view_scale))


func _solve_simulation_view_position() -> void:
	simulation_view_location = Vector2(floor(SimulationViewPos.get_global_position().x - simulation_view_size.x / 2.0),
	floor(SimulationViewPos.get_global_position().y - simulation_view_size.y / 2.0))


func set_sim_view_size(aspect: Vector2) -> void:
	simulation_view_true_size = aspect


func get_simulation_view_position() -> Vector2:
	return simulation_view_location


func get_simulation_view_scale() -> float:
	return simulation_view_scale


func draw_particles(grid_size: int, particle_count: int, 
		particle_positions: PackedVector2Array, particle_radii: PackedFloat32Array) -> void:
	Renderer.render(grid_size, particle_count, particle_positions, 
	particle_radii, simulation_view_size, simulation_view_scale, simulation_view_location)
