class_name UI
extends CanvasLayer

@onready var SimulationViewRect: ColorRect = get_node("Control/SimulationViewArea/SimulationViewRect")
@onready var SimulationViewPos: Control = get_node("Control/SimulationViewArea/SimulationViewRect/SimulationViewPos")
@onready var simulation_view: SimulationViewData

func _process(_delta: float) -> void:
	_update_simulation_view_info()

func _update_simulation_view_info() -> void:
	simulation_view.update_simulation_view_size(SimulationViewRect.get_global_rect().size)
	simulation_view.update_simulation_view_position(SimulationViewPos.get_global_position())

func set_sim_view(sim_view: SimulationViewData) -> void:
	simulation_view = sim_view
