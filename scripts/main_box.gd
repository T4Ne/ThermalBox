class_name MainBox
extends Node2D

var simulation_view: SimulationViewData
var time_step: float
signal ui_info(tps: int, count: int)

@onready var scheduler: Scheduler = Scheduler.new()
@onready var particles: ParticleData
@onready var cells: CellData
@onready var renderer: Renderer = get_node("ParticleRenderer")

func _ready() -> void:
	reinitialize_sim()
	var physics_fps: int = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
	time_step = 1 / float(physics_fps)

func _process(delta: float) -> void:
	renderer.render(particles, cells, simulation_view)
	ui_info.emit(floor(1 / delta), particles.count)
	if Globals.is_paused:
		return
	scheduler.step(time_step)

#func _physics_process(_delta: float) -> void:

func reinitialize_sim() -> void:
	particles = ParticleData.new()
	cells = CellData.new(Globals.default_cell_size, Globals.default_simulation_area)
	scheduler.set_cell_data(cells)
	scheduler.set_particle_data(particles)
	renderer.reinitialize_render()

func place_particle(type: int, mouse_position: Vector2, place_25: bool) -> void:
	var simulation_view_position: Vector2 = simulation_view.simulation_view_position
	var simulation_view_scale: float = simulation_view.simulation_view_scale
	var particle_simulation_position: Vector2 = (mouse_position - simulation_view_position) / simulation_view_scale
	var particle_velocity: Vector2 = Vector2.ZERO
	var particle_radius: float = Globals.default_particle_radius
	var particle_mass: float = Globals.default_particle_mass
	if place_25:
		for y in range(-2, 3):
			for x in range(-2, 3):
				var neighbor_particle_position: Vector2 = particle_simulation_position + Vector2(y * particle_radius * 3, x * particle_radius * 3)
				particles.add_particle(type, neighbor_particle_position, particle_velocity, particle_radius, particle_mass)
	else:
		particles.add_particle(type, particle_simulation_position, particle_velocity, particle_radius, particle_mass)

func place_wall(mouse_position: Vector2) -> void:
	var simulation_view_position: Vector2 = simulation_view.simulation_view_position
	var simulation_view_scale: float = simulation_view.simulation_view_scale
	var size: int = cells.cell_size
	var cell_x: int = floori((mouse_position.x - simulation_view_position.x) / simulation_view_scale) / size
	var cell_y: int = floori((mouse_position.y - simulation_view_position.y) / simulation_view_scale) / size
	var cell_coordinates: Vector2i = Vector2i(cell_x, cell_y)
	cells.toggle_wall(cell_coordinates)

func print_energy() -> void:
	var energy_sum: float = 0.0
	var count: int = particles.count
	
	for particle_id in range(count):
		var mass: float = particles.masses[particle_id]
		var velocity: float = particles.velocities[particle_id].length()
		var kinetic_energy: float = 0.5 * mass * (velocity ** 2)
		#var potential_energy: float = mass * gravity * height
		var total_energy: float = kinetic_energy #+ potential_energy
		energy_sum += total_energy
	
	var temp: float = energy_sum / float(count)
	print("%.0f" % temp)

func set_simulation_view(sim_view: SimulationViewData) -> void:
	simulation_view = sim_view

func reduce_energy() -> void:
	for particle_id in range(particles.count):
		particles.velocities[particle_id] = particles.velocities[particle_id] * 0.8
