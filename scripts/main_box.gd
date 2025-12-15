class_name MainBox
extends Node2D

var simulation_render_state: SimulationRenderState

@onready var scheduler: Scheduler = Scheduler.new()
@onready var world_state: WorldState
@onready var renderer: Renderer = get_node("ParticleRenderer")
var last_physics_time_usec: float = 0.0
var real_tps: float = 0.0
var execution_time_ms: float = 0.0

func _ready() -> void:
	reinitialize_sim()

func frame(_delta: float) -> void:
	simulation_render_state.update_mouse_cell_coords(get_global_mouse_position(), world_state.get_cell_size())
	renderer.render(world_state, simulation_render_state)

func _physics_process(_delta: float) -> void:
	var physics_frame_start_usec: float = Time.get_ticks_usec()
	if last_physics_time_usec > 0.0:
		var time_since_last_call_usec: float = physics_frame_start_usec - last_physics_time_usec
		if time_since_last_call_usec > 0.0:
			var current_real_tps: float = 1000000.0 / time_since_last_call_usec
			real_tps = lerp(real_tps, current_real_tps, 0.1)
	last_physics_time_usec = physics_frame_start_usec
	
	if Globals.config["is_paused"]:
		pass
	else:
		scheduler.step_n_times(Globals.config["time_step"], 2)
	
	var physics_frame_end_time_usec: float = Time.get_ticks_usec()
	var duration_usec: float = physics_frame_end_time_usec - physics_frame_start_usec
	execution_time_ms = lerp(execution_time_ms, duration_usec / 1000.0, 0.1)

func reinitialize_sim() -> void:
	world_state = WorldState.new()
	world_state.setup(true, Globals.config)
	scheduler.setup(world_state, Globals.config)
	renderer.reinitialize_render()

func set_sim_globals() -> void:
	world_state.set_globals(Globals.config)
	scheduler.set_globals(Globals.config)

func place_particle(type: int, mouse_position: Vector2, place_25: bool) -> void:
	var simulation_view_position: Vector2 = simulation_render_state.simulation_view_position
	var simulation_view_scale: float = simulation_render_state.simulation_view_scale
	var particle_simulation_position: Vector2 = (mouse_position - simulation_view_position) / simulation_view_scale
	var particle_velocity: Vector2 = Vector2.ZERO
	var particle_radius: float = world_state.get_particle_radius()
	if place_25:
		for y: int in range(-2, 3):
			for x: int in range(-2, 3):
				var neighbor_particle_position: Vector2 = particle_simulation_position + Vector2(y * particle_radius * 3.95, x * particle_radius * 3.95)
				world_state.add_particle(type, neighbor_particle_position, particle_velocity)
	else:
		world_state.add_particle(type, particle_simulation_position, particle_velocity)

func delete_particles_by_cell(extended_range: bool) -> void:
	var cell_coordinates: Vector2i = simulation_render_state.mouse_cell_coords[0]
	if cell_coordinates == Vector2i(-1, -1):
		return
	if extended_range:
		world_state.delete_particles_by_area(cell_coordinates)
	else:
		world_state.delete_particles_by_cell(cell_coordinates)

func change_particle_temps_by_cell(heating: bool, extended_range: bool) -> void:
	var cell_coordinates: Vector2i = simulation_render_state.mouse_cell_coords[0]
	if cell_coordinates == Vector2i(-1, -1):
		return
	var coef: float
	if heating:
		coef = 1.1
	else:
		coef = 0.90
	if extended_range:
		world_state.change_velocity_by_area(coef, cell_coordinates)
	else:
		world_state.change_velocity_by_cell(coef, cell_coordinates)

func place_wall(type: int) -> void:
	var cell_coordinates: Vector2i = simulation_render_state.mouse_cell_coords[0]
	if cell_coordinates == Vector2i(-1, -1):
		return
	world_state.set_cell_state(cell_coordinates, type)

func place_pump(type: int) -> void:
	var pump_coordinates: Vector2i = simulation_render_state.mouse_cell_coords[1]
	if pump_coordinates == Vector2i(-1, -1):
		return
	var direction_vec: Vector2i = simulation_render_state.mouse_cell_coords[0] - simulation_render_state.mouse_cell_coords[1]
	if direction_vec.x == 0:
		if direction_vec.y > 0:
			world_state.set_cell_state(pump_coordinates, type + 1)
		else:
			world_state.set_cell_state(pump_coordinates, type)
	else:
		if direction_vec.x > 0:
			world_state.set_cell_state(pump_coordinates, type + 3)
		else:
			world_state.set_cell_state(pump_coordinates, type + 2)

func set_simulation_view(render_state_instance: SimulationRenderState) -> void:
	simulation_render_state = render_state_instance

func reduce_energy() -> void:
	var coef: float = 0.8
	world_state.change_velocity(coef)

func delete_particles() -> void:
	world_state.clear_particles()

func _on_particle_spawn_timer_timeout() -> void:
	if Globals.config["is_paused"]:
		return
	world_state.spawn_particles_from_spawners()
