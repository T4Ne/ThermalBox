class_name MainBox
extends Node2D

var simulation_render_state: SimulationRenderState
signal ui_info(tps: int, count: int)

@onready var scheduler: Scheduler = Scheduler.new()
@onready var world_state: WorldState
@onready var renderer: Renderer = get_node("ParticleRenderer")
var mouse_cell_coords: Vector2i = Vector2i(-1, -1)
var prev_mouse_cell_coords: Vector2i = Vector2i(-1, -1)

enum Items {REMOVEWALL, PARTICLE1, PARTICLE2, PARTICLE3, WALLNEUTRAL, WALLCOLD, WALLHOT, PUMP}
var selected_item: Items = Items.REMOVEWALL

func _ready() -> void:
	reinitialize_sim()

func _process(delta: float) -> void:
	simulation_render_state.update_mouse_cell_coords(get_global_mouse_position(), world_state.cell_size)
	renderer.render(world_state, simulation_render_state)
	ui_info.emit(floor(1 / delta), world_state.particle_count)

func _physics_process(_delta: float) -> void:
	if Globals.is_paused:
		return
	scheduler.step(Globals.time_step)

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

func place_wall(type: int, mouse_position: Vector2) -> void:
	var simulation_view_position: Vector2 = simulation_render_state.simulation_view_position
	var simulation_view_scale: float = simulation_render_state.simulation_view_scale
	var size: int = world_state.cell_size
	var cell_x: int = floori((mouse_position.x - simulation_view_position.x) / simulation_view_scale) / size
	var cell_y: int = floori((mouse_position.y - simulation_view_position.y) / simulation_view_scale) / size
	var cell_coordinates: Vector2i = Vector2i(cell_x, cell_y)
	world_state.set_cell_wall_state(cell_coordinates, type)

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
