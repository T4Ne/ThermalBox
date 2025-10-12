extends CanvasLayer

@onready var SimulationViewRect := get_node("Control/SimulationViewArea/SimulationViewRect")
@onready var SimulationViewPos := get_node("Control/SimulationViewArea/SimulationViewPos")
@onready var Renderer := get_node("ParticleRenderer")
var simulation_view_aspect_ratio = Vector2(4.0, 3.0)
var simulation_view_size: Vector2
var simulation_view_location: Vector2
var simulation_view_scale: float
var simulation_view_edge_offset := Vector2(30, 30)


func _process(_delta: float) -> void:
	_update_simulation_view_info()


func _update_simulation_view_info() -> void:
	_solve_simulation_view_size()
	_solve_simulation_view_position()


func _solve_simulation_view_size() -> void:
	var simulation_view_area_size = SimulationViewRect.get_global_rect().size - simulation_view_edge_offset
	simulation_view_scale = min(simulation_view_area_size.x / simulation_view_aspect_ratio.x, simulation_view_area_size.y / simulation_view_aspect_ratio.y)
	simulation_view_size = Vector2(floor(simulation_view_aspect_ratio.x * simulation_view_scale), floor(simulation_view_aspect_ratio.y * simulation_view_scale))


func _solve_simulation_view_position() -> void:
	simulation_view_location = Vector2(floor(SimulationViewPos.get_global_position().x - simulation_view_size.x / 2.0),
	floor(SimulationViewPos.get_global_position().y - simulation_view_size.y / 2.0))


func draw_particles(grid_size: int, simulation_area: Vector2, particle_count: int, 
		particle_positions: PackedVector2Array, particle_radii: PackedFloat32Array) -> void:
	Renderer.render(grid_size, simulation_area, particle_count, particle_positions, 
	particle_radii, simulation_view_size, simulation_view_location)
	
