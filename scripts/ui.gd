class_name UI
extends CanvasLayer

var edge_offset: Vector2 = Vector2(60.0, 60.0)
var last_mouse_cell: Vector2i = Vector2i(-1, -1)
var selected_particle: Particles = Particles.NONE
var selected_item: Items = Items.NONE
var place_25: bool = false
var item_placement_cooldown: bool = false
var borders_toggle: bool = true
var x_edit_value: int = Globals.config["default_simulation_area"].x
var y_edit_value: int = Globals.config["default_simulation_area"].y
 
@onready var SimulationViewRect: ColorRect = get_node("Control/SimulationViewArea/SimulationViewRect")
@onready var SimulationViewPos: Control = get_node("Control/SimulationViewArea/SimulationViewRect/SimulationViewPos")
@onready var simulation_render_state: SimulationRenderState = SimulationRenderState.new()
@onready var main_box: MainBox = get_node("MainBox")
@onready var Pause: Button = get_node("Control/SideBar/MainControls/Pause")
@onready var Gravity: Button = get_node("Control/SideBar/MainControls/Gravity")
@onready var FPSLabel: Label = get_node("Control/SideBar/MainControls/FPSLabel")
@onready var Countlabel: Label = get_node("Control/SideBar/MainControls/CountLabel")
@onready var place_many: CheckButton = $Control/BottomBar/Items/Selected/PlaceMany
@onready var item_place_timer: Timer = get_node("ItemPlaceCoolDown")
@onready var area_x_edit: LineEdit = get_node("Control/SideBar/MainControls/xEditContainer/LineEditx")
@onready var area_y_edit: LineEdit = get_node("Control/SideBar/MainControls/yEditContainer/LineEdity")

@onready var item_texture_lookup: Array[Texture2D] = [preload("uid://bxrcoyxjietag"), preload("uid://c81hsd6ff00fx"), preload("uid://devdprvm0jnhl"),
preload("uid://d0etoy4rpqw2p"), preload("uid://dykc2efd2pjcd"), preload("uid://d08o4eqdmfcwj"), preload("uid://cdbtk1ci2lnxj"), preload("uid://dlum8nkyxy8v8"),
preload("uid://cc25v4y56vtsk"), preload("uid://bs7chhpmiahvk"), preload("uid://yhu03fshf4cd")]

@onready var particle_texture_lookup: Array[Texture2D] = [preload("uid://ixp2pu05yr6e"), preload("uid://b4pe2ijf6ejka"), preload("uid://bph7fk4fxnfu7"),
preload("uid://bvv4q4x1l7a6y"), preload("uid://baw1n4q0yj3ef"), preload("uid://be1qkglmt0umf")]

@onready var pause_textures: Array[Texture2D] = [preload("uid://bm0irqeu6rdxm"), preload("uid://ykkntavghb5k")]
@onready var gravity_button: CheckButton = $Control/SideBar/MainControls/Gravity
@onready var cooling_button: CheckButton = $Control/SideBar/MainControls/Cooling
@onready var primary_action_icon: TextureRect = $Control/BottomBar/Items/Selected/HBoxContainer/VBoxContainer/MarginContainer/TextureRect
@onready var secondary_action_icon: TextureRect = $Control/BottomBar/Items/Selected/HBoxContainer/VBoxContainer2/MarginContainer/TextureRect


enum Items {NONE, WALLNEUTRAL, WALLCOLD, WALLHOT, PUMP, DIODE, SPAWNER, DRAIN, CONDUCTOR, HEATUP, COOLDOWN}
enum Particles {NONE, PARTICLE1, PARTICLE2, PARTICLE3, PARTICLE4, PARTICLE5}

func _ready() -> void:
	DisplayServer.window_set_min_size(Vector2i(1024, 640))
	main_box.set_simulation_view(simulation_render_state)
	_reset()
	_on_particle_1_item_pressed()

func _reset() -> void:
	var simulation_true_size: Vector2i = Globals.config["default_cell_size"] * Globals.config["default_simulation_area"]
	simulation_render_state.reset(simulation_true_size)
	area_x_edit.text = str(x_edit_value)
	area_y_edit.text = str(y_edit_value)

func _process(delta: float) -> void:
	_update_simulation_view_info()
	display_info(main_box.real_tps, main_box.world_state.get_particle_count())
	_handle_gui_input()
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
		Pause.icon = pause_textures[1]
	else:
		Pause.text = "Pause"
		Pause.icon = pause_textures[0]

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

func _handle_gui_input() -> void:
	var new_mouse_cell: Vector2i = simulation_render_state.mouse_cell_coords[0]
	if new_mouse_cell == Vector2i(-1, -1):
		return
	if new_mouse_cell == last_mouse_cell and item_placement_cooldown:
		return
	if Input.is_action_pressed("primary action"):
		_handle_placement(main_box.get_global_mouse_position())
		last_mouse_cell = new_mouse_cell
		item_placement_cooldown = true
		item_place_timer.start()
	elif Input.is_action_pressed("secondary action"):
		_handle_deletion()
		if simulation_render_state.item_placement_mode == simulation_render_state.ItemPlacementMode.PARTICLE:
			simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLEDELETE
		last_mouse_cell = new_mouse_cell
		item_placement_cooldown = true
		item_place_timer.start()
	else:
		if simulation_render_state.item_placement_mode == simulation_render_state.ItemPlacementMode.PARTICLEDELETE:
			simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE

func _on_pause_pressed() -> void:
	toggle_pause()

func _on_reset_pressed() -> void:
	_activate_reset()

func _activate_reset() -> void:
	Globals.config["default_simulation_area"] = Vector2i(x_edit_value, y_edit_value)
	_reset()
	main_box.reinitialize_sim(borders_toggle)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("simulation toggle"):
		toggle_pause()
	if event.is_action_pressed("toggle big selection"):
		if place_25:
			big_selection_toggle(false)
		else:
			big_selection_toggle(true)
	if event.is_action_pressed("clear particles"):
		main_box.delete_particles()
	if event.is_action_pressed("toggle gravity"):
		if Globals.config["gravity_is_on"]:
			gravity_toggle(false)
		else:
			gravity_toggle(true)
	if event.is_action_pressed("toggle cooling"):
		if Globals.config["global_cooling"]:
			cooling_toggle(false)
		else:
			cooling_toggle(true)

func _on_particle_1_item_pressed() -> void:
	selected_particle = Particles.PARTICLE1
	selected_item = Items.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE
	update_item_helper()

func _on_particle_2_item_pressed() -> void:
	selected_particle = Particles.PARTICLE2
	selected_item = Items.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE
	update_item_helper()

func _on_particle_3_item_pressed() -> void:
	selected_particle = Particles.PARTICLE3
	selected_item = Items.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE
	update_item_helper()

func display_info(real_tps: float, count: int) -> void:
	var tps: int = roundi(real_tps)
	FPSLabel.text = "FPS: %d" % tps
	Countlabel.text = "Particle count: %d" % count

func _on_place_many_toggled(toggled_on: bool) -> void:
	big_selection_toggle(toggled_on)

func big_selection_toggle(toggled_on: bool) -> void:
	place_25 = toggled_on
	simulation_render_state.extended_range = toggled_on
	place_many.button_pressed = place_25

func _on_particles_reset_pressed() -> void:
	main_box.delete_particles()

func _on_wall_neutral_pressed() -> void:
	selected_item = Items.WALLNEUTRAL
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	update_item_helper()

func _on_wall_cold_pressed() -> void:
	selected_item = Items.WALLCOLD
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	update_item_helper()

func _on_wall_hot_pressed() -> void:
	selected_item = Items.WALLHOT
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	update_item_helper()

func _on_pump_pressed() -> void:
	selected_item = Items.PUMP
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PUMP
	update_item_helper()

func _on_particle_4_item_pressed() -> void:
	selected_particle = Particles.PARTICLE4
	selected_item = Items.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE
	update_item_helper()

func _on_diode_pressed() -> void:
	selected_item = Items.DIODE
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PUMP
	update_item_helper()

func _on_spawner_pressed() -> void:
	selected_item = Items.SPAWNER
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	update_item_helper()

func _on_drain_pressed() -> void:
	selected_item = Items.DRAIN
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	update_item_helper()

func _on_conductor_pressed() -> void:
	selected_item = Items.CONDUCTOR
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.WALL
	update_item_helper()

func _on_particle_5_item_pressed() -> void:
	selected_particle = Particles.PARTICLE5
	selected_item = Items.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.PARTICLE
	update_item_helper()

func _on_heat_up_pressed() -> void:
	selected_item = Items.HEATUP
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.TEMPCHANGE
	update_item_helper()

func _on_cool_down_pressed() -> void:
	selected_item = Items.COOLDOWN
	selected_particle = Particles.NONE
	simulation_render_state.item_placement_mode = simulation_render_state.ItemPlacementMode.TEMPCHANGE
	update_item_helper()

func _on_item_place_cool_down_timeout() -> void:
	item_placement_cooldown = false

func _on_borders_toggled(toggled_on: bool) -> void:
	borders_toggle = toggled_on

func _on_line_editx_text_submitted(new_text: String) -> void:
	if new_text.is_valid_int():
		var new_x_value: int = int(new_text)
		if new_x_value <= 0:
			submit_error(true)
		elif new_x_value * y_edit_value > 5000:
			submit_error(true)
		else:
			area_x_edit.remove_theme_stylebox_override("normal")
			area_x_edit.release_focus()
			x_edit_value = new_x_value
	else:
		submit_error(true)

func _on_line_edity_text_submitted(new_text: String) -> void:
	if new_text.is_valid_int():
		var new_y_value: int = int(new_text)
		if new_y_value <= 0:
			submit_error(false)
		elif new_y_value * x_edit_value > 5000:
			submit_error(false)
		else:
			area_y_edit.remove_theme_stylebox_override("normal")
			area_y_edit.release_focus()
			y_edit_value = new_y_value
	else:
		submit_error(false)

func submit_error(is_x: bool) -> void:
	if is_x:
		var stylebox: StyleBoxFlat = area_x_edit.get_theme_stylebox("normal").duplicate()
		stylebox.bg_color = Color("83292b")
		area_x_edit.add_theme_stylebox_override("normal", stylebox)
		area_x_edit.release_focus()
	else:
		var stylebox: StyleBoxFlat = area_y_edit.get_theme_stylebox("normal").duplicate()
		stylebox.bg_color = Color("83292b")
		area_y_edit.add_theme_stylebox_override("normal", stylebox)
		area_y_edit.release_focus()

func _on_cooling_toggled(toggled_on: bool) -> void:
	cooling_toggle(toggled_on)

func cooling_toggle(toggled_on: bool) -> void:
	Globals.config["global_cooling"] = toggled_on
	main_box.set_sim_globals()
	cooling_button.button_pressed = toggled_on

func _on_gravity_toggled(toggled_on: bool) -> void:
	gravity_toggle(toggled_on)

func gravity_toggle(toggled_on: bool) -> void:
	Globals.config["gravity_is_on"] = toggled_on
	main_box.set_sim_globals()
	gravity_button.button_pressed = toggled_on

func update_item_helper() -> void:
	assert(selected_item == Items.NONE or selected_particle == Particles.NONE)
	var new_primary_icon: Texture2D
	var new_secondary_icon: Texture2D
	if selected_item != Items.NONE:
		new_primary_icon = item_texture_lookup[selected_item]
		new_secondary_icon = item_texture_lookup[0]
	else:
		new_primary_icon = particle_texture_lookup[selected_particle]
		new_secondary_icon = particle_texture_lookup[0]
	primary_action_icon.texture = new_primary_icon
	secondary_action_icon.texture = new_secondary_icon

func _on_exit_pressed() -> void:
	get_tree().quit()
