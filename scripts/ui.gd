class_name UI
extends CanvasLayer

var edge_offset: Vector2 = Vector2(60.0, 60.0)

@onready var SimulationViewRect: ColorRect = get_node("Control/SimulationViewArea/SimulationViewRect")
@onready var SimulationViewPos: Control = get_node("Control/SimulationViewArea/SimulationViewRect/SimulationViewPos")
@onready var SelectedLabel: Label = get_node("Control/BottomBar/ItemButtons/Selected")
@onready var simulation_render_state: SimulationRenderState
@onready var main_box: MainBox = get_node("MainBox")
@onready var Pause: Button = get_node("Control/SideBar/MainControls/Pause")
@onready var Gravity: Button = get_node("Control/SideBar/MainControls/Gravity")
@onready var FPSLabel: Label = get_node("Control/SideBar/MainControls/FPSLabel")
@onready var Countlabel: Label = get_node("Control/SideBar/MainControls/CountLabel")

enum Items {NONE, WALLNEUTRAL, WALLCOLD, WALLHOT, PUMP, DIODE, SPAWNER, DRAIN, CONDUCTOR, HEATUP, COOLDOWN}
enum Particles {NONE, PARTICLE1, PARTICLE2, PARTICLE3, PARTICLE4, PARTICLE5}

var selected_particle: Particles = Particles.NONE
var selected_item: Items = Items.NONE
var particle_delete_mode: bool = false
var place_25: bool = false

func _ready() -> void:
	var simulation_true_size: Vector2i = Globals.config["default_cell_size"] * Globals.config["default_simulation_area"]
	simulation_render_state = SimulationRenderState.new(simulation_true_size, edge_offset)
	main_box.set_simulation_view(simulation_render_state)

func _process(delta: float) -> void:
	_update_simulation_view_info()
	display_info(main_box.real_tps, main_box.world_state.get_particle_count())
	main_box.frame(delta)

func _update_simulation_view_info() -> void:
	simulation_render_state.update_simulation_view_size(SimulationViewRect.get_global_rect().size)
	simulation_render_state.update_simulation_view_position(SimulationViewPos.get_global_position())

func set_sim_view(render_state_instance: SimulationRenderState) -> void:
	simulation_render_state = render_state_instance

func toggle_pause() -> void:
	Globals.config["is_paused"] = not Globals.config["is_paused"]
	if Globals.config["is_paused"]:
		Pause.text = "Resume"
	else:
		Pause.text = "Pause"

func _handle_placement(mouse_position: Vector2) -> void:
	assert(selected_item == Items.NONE or selected_particle == Particles.NONE)
	
	if selected_item != Items.NONE:
		match selected_item:
			Items.WALLNEUTRAL:
				main_box.place_wall(1)
			Items.WALLCOLD:
				main_box.place_wall(2)
			Items.WALLHOT:
				main_box.place_wall(3)
			Items.CONDUCTOR:
				main_box.place_wall(18)
			Items.PUMP:
				main_box.place_pump(4)
			Items.DIODE:
				main_box.place_pump(8)
			Items.SPAWNER:
				main_box.place_wall(12)
			Items.DRAIN:
				main_box.place_wall(17)
			Items.HEATUP:
				main_box.change_particle_temps_by_cell(true, place_25)
			Items.COOLDOWN:
				main_box.change_particle_temps_by_cell(false, place_25)
	else:
		match selected_particle:
			Particles.PARTICLE1:
				main_box.place_particle(0, mouse_position, place_25)
			Particles.PARTICLE2:
				main_box.place_particle(1, mouse_position, place_25)
			Particles.PARTICLE3:
				main_box.place_particle(2, mouse_position, place_25)
			Particles.PARTICLE4:
				main_box.place_particle(3, mouse_position, place_25)
			Particles.PARTICLE5:
				main_box.place_particle(4, mouse_position, place_25)

func _handle_deletion() -> void:
	assert(selected_item == Items.NONE or selected_particle == Particles.NONE)
	if selected_particle != Particles.NONE:
		main_box.delete_particles_by_cell(place_25)
	else:
		main_box.place_wall(0)

func _on_particle_1_item_pressed() -> void:
	selected_particle = Particles.PARTICLE1
	selected_item = Items.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE
	SelectedLabel.text = "Selected: Particle 1"

func _on_simulation_view_gui_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("primary action"):
		_handle_placement(main_box.get_global_mouse_position())
	elif Input.is_action_pressed("secondary action"):
		_handle_deletion()
		if simulation_render_state.item_placement_mode == simulation_render_state.ItemPlacementMode.PARTICLE:
			simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLEDELETE
	else:
		if simulation_render_state.item_placement_mode == simulation_render_state.ItemPlacementMode.PARTICLEDELETE:
			simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE

func _on_pause_pressed() -> void:
	toggle_pause()

func _on_reset_pressed() -> void:
	main_box.reinitialize_sim()

func _on_gravity_pressed() -> void:
	Globals.config["gravity_is_on"] = not Globals.config["gravity_is_on"]
	if Globals.config["gravity_is_on"]:
		Gravity.text = "Gravity Off"
	else:
		Gravity.text = "Gravity On"
	main_box.set_sim_globals()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("simulation toggle"):
		toggle_pause()
	if event.is_action_pressed("reduce energy"):
		main_box.reduce_energy()

func _on_particle_2_item_pressed() -> void:
	selected_particle = Particles.PARTICLE2
	selected_item = Items.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE
	SelectedLabel.text = "Selected: Particle 2"

func _on_particle_3_item_pressed() -> void:
	selected_particle = Particles.PARTICLE3
	selected_item = Items.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE
	SelectedLabel.text = "Selected: Particle 3"

func display_info(real_tps: float, count: int) -> void:
	var tps: int = roundi(real_tps)
	FPSLabel.text = "FPS: %d" % tps
	Countlabel.text = "Count: %d" % count

func _on_place_many_toggled(toggled_on: bool) -> void:
	place_25 = toggled_on
	simulation_render_state.extended_range = toggled_on

func _on_particles_reset_pressed() -> void:
	main_box.delete_particles()

func _on_wall_neutral_pressed() -> void:
	selected_item = Items.WALLNEUTRAL
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	SelectedLabel.text = "Selected: Neutral Wall"

func _on_wall_cold_pressed() -> void:
	selected_item = Items.WALLCOLD
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	SelectedLabel.text = "Selected: Cold Wall"

func _on_wall_hot_pressed() -> void:
	selected_item = Items.WALLHOT
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	SelectedLabel.text = "Selected: Hot Wall"

func _on_pump_pressed() -> void:
	selected_item = Items.PUMP
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PUMP
	SelectedLabel.text = "Selected: Pump"

func _on_particle_4_item_pressed() -> void:
	selected_particle = Particles.PARTICLE4
	selected_item = Items.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE
	SelectedLabel.text = "Selected: Particle 4"

func _on_diode_pressed() -> void:
	selected_item = Items.DIODE
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PUMP
	SelectedLabel.text = "Selected: Diode"

func _on_spawner_pressed() -> void:
	selected_item = Items.SPAWNER
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	SelectedLabel.text = "Selected: Spawner"

func _on_drain_pressed() -> void:
	selected_item = Items.DRAIN
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	SelectedLabel.text = "Selected: Drain"

func _on_conductor_pressed() -> void:
	selected_item = Items.CONDUCTOR
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	SelectedLabel.text = "Selected: Conductor"

func _on_particle_5_item_pressed() -> void:
	selected_particle = Particles.PARTICLE5
	selected_item = Items.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE
	SelectedLabel.text = "Selected: Particle 5"

func _on_heat_up_pressed() -> void:
	selected_item = Items.HEATUP
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.TEMPCHANGE
	SelectedLabel.text = "Selected: Heat Up"

func _on_cool_down_pressed() -> void:
	selected_item = Items.COOLDOWN
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.TEMPCHANGE
	SelectedLabel.text = "Selected: Cool Down"
