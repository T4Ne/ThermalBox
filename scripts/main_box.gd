class_name MainBox
extends Node2D

var simulation_render_state: SimulationRenderState

@onready var scheduler: Scheduler = Scheduler.new()
@onready var world_state: WorldState
@onready var renderer: Renderer = get_node("ParticleRenderer")
var mouse_cell_coords: Vector2i = Vector2i(-1, -1)
var prev_mouse_cell_coords: Vector2i = Vector2i(-1, -1)
var last_physics_time_usec: float = 0.0
var real_tps: float = 0.0
var execution_time_ms: float = 0.0

enum Items {REMOVEWALL, PARTICLE1, PARTICLE2, PARTICLE3, WALLNEUTRAL, WALLCOLD, WALLHOT, PUMP}
var selected_item: Items = Items.REMOVEWALL

func _ready() -> void:
	reinitialize_sim()

func frame(_delta: float) -> void:
	simulation_render_state.update_mouse_cell_coords(get_global_mouse_position(), world_state.cell_size)
	renderer.render(world_state, simulation_render_state)

func _physics_process(_delta: float) -> void:
	var physics_frame_start_usec: float = Time.get_ticks_usec()
	if last_physics_time_usec > 0.0:
		var time_since_last_call_usec: float = physics_frame_start_usec - last_physics_time_usec
		if time_since_last_call_usec > 0.0:
			var current_real_tps: float = 1000000.0 / time_since_last_call_usec
			real_tps = lerp(real_tps, current_real_tps, 0.1)
	last_physics_time_usec = physics_frame_start_usec
	
	if Globals.is_paused:
		pass
	else:
		scheduler.step(Globals.time_step)
	
	var physics_frame_end_time_usec: float = Time.get_ticks_usec()
	var duration_usec: float = physics_frame_end_time_usec - physics_frame_start_usec
	execution_time_ms = lerp(execution_time_ms, duration_usec / 1000.0, 0.1)

func reinitialize_sim() -> void:
	world_state = WorldState.new(Globals.default_cell_size, Globals.default_simulation_area)
	scheduler.set_world_state(world_state)
	renderer.reinitialize_render()

func place_particle(type: int, mouse_position: Vector2, place_25: bool) -> void:
	var simulation_view_position: Vector2 = simulation_render_state.simulation_view_position
	var simulation_view_scale: float = simulation_render_state.simulation_view_scale
	var particle_simulation_position: Vector2 = (mouse_position - simulation_view_position) / simulation_view_scale
	var particle_velocity: Vector2 = Vector2.ZERO
	var particle_radius: float = Globals.default_particle_radius
	var particle_mass: float = Globals.default_particle_mass
	if place_25:
		for y: int in range(-2, 3):
			for x: int in range(-2, 3):
				var neighbor_particle_position: Vector2 = particle_simulation_position + Vector2(y * particle_radius * 3.9, x * particle_radius * 3.9)
				world_state.add_particle(type, neighbor_particle_position, particle_velocity, particle_radius, particle_mass)
	else:
		world_state.add_particle(type, particle_simulation_position, particle_velocity, particle_radius, particle_mass)

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

func print_energy() -> void:
	var energy_sum: float = 0.0
	var count: int = world_state.particle_count
	
	for particle_id: int in range(count):
		var mass: float = world_state.particle_masses[particle_id]
		var velocity: float = world_state.particle_velocities[particle_id].length()
		var kinetic_energy: float = 0.5 * mass * (velocity ** 2)
		#var potential_energy: float = mass * gravity * height
		var total_energy: float = kinetic_energy #+ potential_energy
		energy_sum += total_energy
	
	var temp: float = energy_sum / float(count)
	print("%.0f" % temp)

func set_simulation_view(render_state_instance: SimulationRenderState) -> void:
	simulation_render_state = render_state_instance

func reduce_energy() -> void:
	for particle_id: int in range(world_state.particle_count):
		world_state.particle_velocities[particle_id] = world_state.particle_velocities[particle_id] * 0.8

func delete_particles() -> void:
	world_state.delete_particles()
