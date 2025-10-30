class_name MainBox
extends Node2D

var cell_size: int = 10
var cell_area: Vector2i = Vector2i(80, 60)
var simulation_size: Vector2i = cell_area * cell_size
var edge_offset: Vector2 = Vector2(60.0, 60.0)
@onready var scheduler: Scheduler = Scheduler.new()
@onready var particles: ParticleData = ParticleData.new()
@onready var cells: CellData = CellData.new(cell_size, cell_area)
@onready var simulation_view_data: SimulationViewData = SimulationViewData.new(simulation_size, edge_offset)
@onready var ui: UI = get_node("UI")
@onready var renderer: Renderer = get_node("UI/ParticleRenderer")
var is_paused: bool = false


func _ready() -> void:
	ui.set_sim_view(simulation_view_data)
	scheduler.set_cell_data(cells)
	scheduler.set_particle_data(particles)
	_build_borders()

func _process(_delta: float) -> void:
	renderer.render(particles, cells, simulation_view_data)

func _physics_process(delta: float) -> void:
	if is_paused:
		return
	scheduler.step(delta)

func _build_borders() -> void:
	var cell_array_size: int = cells.cell_count
	var cell_area_row_size: int = cells.cell_area.x
	for cell_indx in range(cell_array_size):
		if cell_indx < cell_area_row_size:
			cells.set_cell_wall_state(cell_indx, true)
			cells.change_wall_count_by(1)
			continue
		elif cell_indx >= cell_array_size - cell_area_row_size:
			cells.set_cell_wall_state(cell_indx, true)
			cells.change_wall_count_by(1)
			continue
		var cell_row_indx: int = cell_indx % cell_area_row_size
		if cell_row_indx == 0:
			cells.set_cell_wall_state(cell_indx, true)
			cells.change_wall_count_by(1)
		elif cell_row_indx == cell_area_row_size - 1:
			cells.set_cell_wall_state(cell_indx, true)
			cells.change_wall_count_by(1)
		else:
			cells.set_cell_wall_state(cell_indx, false)

func place_particle(mouse_position: Vector2) -> void:
	var simulation_view_position: Vector2 = simulation_view_data.simulation_view_position
	var simulation_view_scale: float = simulation_view_data.simulation_view_scale
	var particle_simulation_position: Vector2 = (mouse_position - simulation_view_position) / simulation_view_scale
	var particle_velocity: Vector2 = Vector2.ZERO
	var particle_radius: float = 5.0
	var particle_mass: float = 1.0
	particles.add_particle(particle_simulation_position, particle_velocity, particle_radius, particle_mass)

func place_wall(_mouse_position: Vector2) -> void:
	pass

func _on_simulation_view_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("Place particle"):
		place_particle(get_global_mouse_position())
	if event.is_action_pressed("Place wall"):
		place_wall(get_global_mouse_position())
