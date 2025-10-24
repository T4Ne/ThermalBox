extends Node2D
@onready var Scheduler: Object = preload("res://scripts/scheduler.gd").Scheduler.new()
@onready var ParticleData: Object = preload("res://scripts/data_objects.gd").ParticleData.new()
@onready var CellData: Object = preload("res://scripts/data_objects.gd").CellData.new()
@onready var UI: Node = get_node("UI")
var is_paused: bool = false
var particle_count: int = 0
var particle_positions: PackedVector2Array = []
var particle_velocities: PackedVector2Array = []
var particle_accelerations: PackedVector2Array = []
var particle_radii: PackedFloat32Array = []
var particle_masses: PackedFloat32Array = []
var wall_count: int = 0
var cell_size: int = 10
var cell_area: Vector2i = Vector2i(80, 60)
var cell_count: int
var cell_offsets: PackedInt32Array = []
var cell_particle_indexes: PackedInt32Array = []
var cell_is_filled: PackedByteArray = []


func _ready() -> void:
	UI.set_sim_view_size(cell_area * cell_size)
	cell_is_filled.resize(int(cell_area.x * cell_area.y))
	cell_count = cell_area.x * cell_area.y
	_build_borders()


func _process(_delta: float) -> void:
	UI.draw_simulation(wall_count, cell_count, cell_size, cell_is_filled, cell_area, 
particle_count, particle_positions, particle_radii)


func _physics_process(delta: float) -> void:
	if is_paused:
		return
	Scheduler.step(delta, particle_count, particle_positions, particle_velocities, particle_accelerations,
	particle_radii, particle_masses)


func _build_borders() -> void:
	var cell_array_size: int = len(cell_is_filled)
	var cell_area_row_size: int = cell_area.x
	for cell_indx in range(cell_array_size):
		if cell_indx < cell_area_row_size:
			cell_is_filled[cell_indx] = true
			wall_count += 1
			continue
		elif cell_indx >= cell_array_size - cell_area_row_size:
			cell_is_filled[cell_indx] = true
			wall_count += 1
			continue
		var cell_row_indx: int = cell_indx % cell_area_row_size
		if cell_row_indx == 0:
			cell_is_filled[cell_indx] = true
			wall_count += 1
		elif cell_row_indx == cell_area_row_size - 1:
			cell_is_filled[cell_indx] = true
			wall_count += 1
		else:
			cell_is_filled[cell_indx] = false


func place_particle(mouse_position: Vector2) -> void:
	var simulation_view_position: Vector2 = UI.get_simulation_view_position()
	var simulation_view_scale: float = UI.get_simulation_view_scale()
	var particle_simulation_position: Vector2 = (mouse_position - simulation_view_position) / simulation_view_scale
	var particle_velocity: Vector2 = Vector2.ZERO
	var particle_radius: float = 5.0
	var particle_mass: float = 1.0
	add_particle_to_sim(particle_simulation_position, particle_velocity, particle_radius, particle_mass)


func add_particle_to_sim(particle_position: Vector2, particle_velocity: Vector2, particle_radius: float, particle_mass: float) -> void:
		assert(
			particle_velocities.size() == particle_count
			and particle_radii.size() == particle_count
			and particle_masses.size() == particle_count
			and particle_accelerations.size() == particle_count,
			"ParticleDataDeSyncError: particle arrays have mismatched sizes"
		)
		particle_count += 1
		particle_positions.append(particle_position)
		particle_velocities.append(particle_velocity)
		particle_accelerations.append(Vector2.ZERO)
		particle_radii.append(particle_radius)
		particle_masses.append(particle_mass)


func _on_simulation_view_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("Place particle"):
		place_particle(get_global_mouse_position())
