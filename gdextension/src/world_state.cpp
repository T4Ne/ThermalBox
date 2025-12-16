#include "world_state.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <cmath>

using namespace godot;

void WorldState::_bind_methods(){
	ClassDB::bind_method(D_METHOD("get_particle_count"), &WorldState::get_particle_count);
	ClassDB::bind_method(D_METHOD("get_cell_size"), &WorldState::get_cell_size);
	ClassDB::bind_method(D_METHOD("add_particle"), &WorldState::add_particle);
	ClassDB::bind_method(D_METHOD("set_cell_state"), &WorldState::set_cell_state);
	ClassDB::bind_method(D_METHOD("clear_particles"), &WorldState::clear_particles);
	ClassDB::bind_method(D_METHOD("spawn_particles_from_spawners"), &WorldState::spawn_particles_from_spawners);
	ClassDB::bind_method(D_METHOD("get_particle_positions"), &WorldState::get_particle_positions);
	ClassDB::bind_method(D_METHOD("get_particle_radius"), &WorldState::get_particle_radius);
	ClassDB::bind_method(D_METHOD("get_particle_types"), &WorldState::get_particle_types);
	ClassDB::bind_method(D_METHOD("get_wall_count"), &WorldState::get_wall_count);
	ClassDB::bind_method(D_METHOD("get_pump_count"), &WorldState::get_pump_count);
	ClassDB::bind_method(D_METHOD("get_diode_count"), &WorldState::get_diode_count);
	ClassDB::bind_method(D_METHOD("get_spawner_count"), &WorldState::get_spawner_count);
	ClassDB::bind_method(D_METHOD("get_cell_count"), &WorldState::get_cell_count);
	ClassDB::bind_method(D_METHOD("get_cell_types"), &WorldState::get_cell_types);
	ClassDB::bind_method(D_METHOD("get_type_category_map"), &WorldState::get_type_category_map);
	ClassDB::bind_method(D_METHOD("get_cell_area"), &WorldState::get_cell_area);
	ClassDB::bind_method(D_METHOD("change_velocity"), &WorldState::change_velocity);
	ClassDB::bind_method(D_METHOD("setup"), &WorldState::setup);
	ClassDB::bind_method(D_METHOD("get_conductor_count"), &WorldState::get_conductor_count);
	ClassDB::bind_method(D_METHOD("get_conductor_energies"), &WorldState::get_conductor_energies);
	ClassDB::bind_method(D_METHOD("set_globals"), &WorldState::set_globals);
	ClassDB::bind_method(D_METHOD("delete_particles_by_cell"), &WorldState::delete_particles_by_cell);
	ClassDB::bind_method(D_METHOD("delete_particles_by_area"), &WorldState::delete_particles_by_area);
	ClassDB::bind_method(D_METHOD("change_velocity_by_cell"), &WorldState::change_velocity_by_cell);
	ClassDB::bind_method(D_METHOD("change_velocity_by_area"), &WorldState::change_velocity_by_area);
}

WorldState::WorldState() {
	type_category_map = {
		CAT_NONE, CAT_WALL, CAT_WALL, CAT_WALL, CAT_PUMP, CAT_PUMP,
		CAT_PUMP, CAT_PUMP, CAT_DIODE, CAT_DIODE, CAT_DIODE, CAT_DIODE,
		CAT_SPAWNER, CAT_SPAWNER, CAT_SPAWNER, CAT_SPAWNER, CAT_SPAWNER, CAT_SPAWNER,
		CAT_CONDUCTOR, CAT_SPAWNER
	};
}

WorldState::~WorldState() {
}

void WorldState::setup(bool borders, const Dictionary& config) {
	set_globals(config);
	cell_types.resize(cell_count);
	cell_types.fill((uint8_t)EMPTY);
	cell_particle_offsets.resize(cell_count + 1);
	conductor_energies.resize(cell_count);
	conductor_energies.fill(0.0f);
	if (borders) {
		build_borders();
	}
	build_neighbor_offsets();
}

void WorldState::set_globals(const Dictionary& config) {
	
	cell_size = config["default_cell_size"];
	inverted_cell_size = 1.0 / (double)cell_size;
	cell_area = config["default_simulation_area"];
	cell_count = cell_area.x * cell_area.y;
	neighbor_range = config["neighbor_range"];
	neighbor_count = std::pow(neighbor_range * 2 + 1, 2);
	particle_mass_by_type = config["default_particle_mass_by_type"];
	particle_radius = config["default_particle_radius"];
}

void WorldState::build_neighbor_offsets() {
	cell_neighbor_offsets.resize(cell_count + 1);
	cell_neighbor_offsets.fill(0);
	cell_neighbor_ids.resize(neighbor_count * cell_count);

	int write_idx = 0;
	int32_t* neighbor_ids_ptr = cell_neighbor_ids.ptrw();
	int32_t* offsets_ptr = cell_neighbor_offsets.ptrw();

	for (int cell_id = 0; cell_id < cell_count; cell_id++) {
		PackedInt32Array neighbors = get_neighbor_cells(cell_id);
		const int32_t* n_ptr = neighbors.ptr();
		for (int i = 0; i < neighbors.size(); i++) {
			neighbor_ids_ptr[write_idx] = n_ptr[i];
			write_idx++;
		}
		offsets_ptr[cell_id + 1] = write_idx;
	}
}

PackedInt32Array WorldState::get_neighbor_cells(int cell_id) const {
	int row_size = cell_area.x;
	int column_size = cell_area.y;
	int cell_x = cell_id % row_size;
	int cell_y = cell_id / row_size;

	PackedInt32Array neighbor_ids;
	neighbor_ids.resize(neighbor_count);
	int32_t* ptr = neighbor_ids.ptrw();

	int local_idx = 0;
	int range_start = -neighbor_range;
	int range_end = neighbor_range + 1;

	for (int local_y = range_start; local_y < range_end; local_y++) {
		for (int local_x = range_start; local_x < range_end; local_x++) {
			int n_x = cell_x + local_x;
			int n_y = cell_y + local_y;
			if (n_x < 0 || n_x >= row_size || n_y < 0 || n_y >= column_size) {
				ptr[local_idx] = -1;
			}
			else {
				ptr[local_idx] = n_x + n_y * row_size;
			}
			local_idx++;
		}
	}
	return neighbor_ids;
}

void WorldState::set_cell_state(Vector2i arr_pos, int new_type) {
	int cell_id = arr_pos.x + arr_pos.y * cell_area.x;
	if (cell_id < 0 || cell_id >= cell_types.size()) return;

	uint8_t old_type = cell_types[cell_id];
	if (old_type == new_type) return;

	update_count_by_category(type_category_map[old_type], -1);
	update_count_by_category(type_category_map[new_type], 1);

	if (type_category_map[new_type] == CAT_CONDUCTOR) {
		conductor_energies[cell_id] = 0.0f;
	}

	cell_types[cell_id] = (uint8_t) new_type;
}

void WorldState::update_count_by_category(int category, int change) {
	switch (category) {
	case CAT_WALL: wall_count += change; break;
	case CAT_PUMP: pump_count += change; break;
	case CAT_DIODE: diode_count += change; break;
	case CAT_SPAWNER: spawner_count += change; break;
	case CAT_CONDUCTOR: conductor_count += change; break;
	}
}

void WorldState::build_borders() {
	int row_size = cell_area.x;
	uint8_t* types_ptr = cell_types.ptrw();
	
	for (int cell_id = 0; cell_id < cell_count; cell_id++) {
		bool is_border = false;
		if (cell_id < row_size) is_border = true;
		else if (cell_id >= cell_count - row_size) is_border = true;
		else {
			int col = cell_id % row_size;
			if (col == 0 || col == row_size - 1) is_border = true;
		}
		if (is_border) {
			types_ptr[cell_id] = (uint8_t) NORMWALL;
			wall_count++;
		}
	}
}

void WorldState::build_cell_map() {
	occupied_cell_ids.clear();
	cell_particle_offsets.fill(0);
	cell_particle_ids.clear();
	int non_empty_cells = 0;
	int32_t* offsets_ptr = cell_particle_offsets.ptrw();
	Vector2* positions_ptr = particle_positions.ptrw();
	uint8_t* cell_types_ptr = cell_types.ptrw();
	uint8_t* par_types_ptr = particle_types.ptrw();

	// Count particles per cell, particle bounds check, convert spawners
	for (int par_id = 0; par_id < particle_positions.size(); par_id++) {
		Vector2 par_position = positions_ptr[par_id];
		if (par_position.x == -1.0f && par_position.y == -1.0f) continue;

		int cell_x = (int)std::floor(par_position.x * inverted_cell_size);
		int cell_y = (int)std::floor(par_position.y * inverted_cell_size);
		if (cell_x < 0 || cell_x >= cell_area.x || cell_y < 0 || cell_y >= cell_area.y) {
			particle_count--;
			positions_ptr[par_id] = Vector2(-1.0, -1.0);
			deleted_particles.push_back(par_id);
			continue;
		}
		int cell_id = cell_x + cell_y * cell_area.x;
		if (cell_types_ptr[cell_id] == DRAIN) {
			particle_count--;
			positions_ptr[par_id] = Vector2(-1.0, -1.0);
			deleted_particles.push_back(par_id);
			continue;
		}
		if (cell_types_ptr[cell_id] == SPAWNERNONE) {
			switch (par_types_ptr[par_id]) {
			case 0: cell_types_ptr[cell_id] = SPAWNER1; break;
			case 1: cell_types_ptr[cell_id] = SPAWNER2; break;
			case 2: cell_types_ptr[cell_id] = SPAWNER3; break;
			case 3: cell_types_ptr[cell_id] = SPAWNER4; break;
			case 4: cell_types_ptr[cell_id] = SPAWNER5; break;
			}
		}
		if (offsets_ptr[cell_id] == 0) {
			non_empty_cells++;
			occupied_cell_ids.append(cell_id);
		}
		offsets_ptr[cell_id]++;
	}
	occupied_cell_count = non_empty_cells;

	// Exclusive prefix sum
	int run_sum = 0;
	for (int cell_id = 0; cell_id < cell_count + 1; cell_id++) {
		int temp = offsets_ptr[cell_id];
		offsets_ptr[cell_id] = run_sum;
		run_sum += temp;
	}
	if (cell_particle_ids.size() != run_sum) {
		cell_particle_ids.resize(run_sum);
	}

	// Scatter pass
	int32_t* cell_par_ptr = cell_particle_ids.ptrw();
	PackedInt32Array write_cursor = cell_particle_offsets.duplicate();
	int32_t* cursor_ptr = write_cursor.ptrw();
	for (int par_id = 0; par_id < particle_positions.size(); par_id++) {
		Vector2 par_position = positions_ptr[par_id];
		if (par_position.x == -1.0f && par_position.y == -1.0f) continue;
		int cell_x = (int)std::floor(par_position.x * inverted_cell_size);
		int cell_y = (int)std::floor(par_position.y * inverted_cell_size);
		int cell_id = cell_x + cell_y * cell_area.x;
		int destination = cursor_ptr[cell_id];
		cell_par_ptr[destination] = par_id;
		cursor_ptr[cell_id] = destination + 1;
	}
}

void WorldState::add_particle(int type, Vector2 position, Vector2 velocity) {

	if (!deleted_particles.empty()) {
		int par_id = deleted_particles.back();
		deleted_particles.pop_back();
		particle_count++;
		particle_types[par_id] = (uint8_t) type;
		particle_positions[par_id] = position;
		particle_velocities[par_id] = velocity;
		particle_accelerations[par_id] = Vector2(0.0, 0.0);
		particle_masses[par_id] = particle_mass_by_type[type];
	}
	else {
		particle_count++;
		particle_types.append((uint8_t) type);
		particle_positions.append(position);
		particle_velocities.append(velocity);
		particle_accelerations.append(Vector2(0.0, 0.0));
		particle_masses.append(particle_mass_by_type[type]);
	}
}

void WorldState::clear_particles() {
	particle_count = 0;
	particle_types.clear();
	particle_positions.clear();
	particle_velocities.clear();
	particle_accelerations.clear();
	particle_masses.clear();
	deleted_particles.clear();
}

void WorldState::delete_particle(int id) {
	if (id < 0 || id >= particle_positions.size()) return;
	Vector2 pos = particle_positions[id];
	if (pos.x == -1.0f && pos.y == -1.0f) return;
	particle_count--;
	particle_positions[id] = Vector2(-1.0, -1.0);
	deleted_particles.push_back(id);
}

void WorldState::delete_particles_by_cell(Vector2i arr_pos) {
	int cell_id = arr_pos.x + arr_pos.y * cell_area.x;
	if (cell_id < 0 || cell_id >= cell_count) return;

	int start = cell_particle_offsets[cell_id];
	int end = cell_particle_offsets[cell_id + 1];
	for (int i = start; i < end; i++) {
		int par_id = cell_particle_ids[i];
		delete_particle(par_id);
	}
}

void WorldState::delete_particles_by_area(Vector2i arr_pos) {
	int cell_id = arr_pos.x + arr_pos.y * cell_area.x;
	if (cell_id < 0 || cell_id >= cell_count) return;

	int neighbors_start = cell_neighbor_offsets[cell_id];
	int neighbors_end = cell_neighbor_offsets[cell_id + 1];
	for (int i = neighbors_start; i < neighbors_end; i++) {
		int neighbor_id = cell_neighbor_ids[i];
		if (neighbor_id < 0) continue;
		int particles_start = cell_particle_offsets[neighbor_id];
		int particles_end = cell_particle_offsets[neighbor_id + 1];
		for (int j = particles_start; j < particles_end; j++) {
			int par_id = cell_particle_ids[j];
			delete_particle(par_id);
		}
	}
}

void WorldState::spawn_particles_from_spawners() {
	if (spawner_count <= 0) return;

	const uint8_t* types_ptr = cell_types.ptr();

	for (int cell_id = 0; cell_id < cell_count; cell_id++) {
		int cell_type = types_ptr[cell_id];
		if (cell_type >= type_category_map.size()) continue;

		if (type_category_map[cell_type] != CAT_SPAWNER) continue;

		int par_type = 0;
		switch (cell_type) {
		case SPAWNER1: par_type = 0; break;
		case SPAWNER2: par_type = 1; break;
		case SPAWNER3: par_type = 2; break;
		case SPAWNER4: par_type = 3; break;
		case SPAWNER5: par_type = 4; break;
		default: continue;
		}
		int cell_x = cell_id % cell_area.x;
		int cell_y = cell_id / cell_area.x;
		Vector2 pos = Vector2((float)cell_x * (float)cell_size + (float)cell_size * 0.5, (float)cell_y * (float)cell_size + (float)cell_size * 0.5);
		double angle = UtilityFunctions::deg_to_rad(UtilityFunctions::randf_range(0, 360));
		Vector2 vel = Vector2(cos(angle), sin(angle)) * 5.0;

		add_particle(par_type, pos, vel);
	}
}

void WorldState::change_velocity(float coef) {
	Vector2* vel_ptr = particle_velocities.ptrw();
	for (int par_id = 0; par_id < particle_velocities.size(); par_id++) {
		vel_ptr[par_id] *= coef;
	}
}

void WorldState::change_velocity_by_cell(float coef, Vector2i arr_pos) {
	int cell_id = arr_pos.x + arr_pos.y * cell_area.x;
	if (cell_id < 0 || cell_id >= cell_count) return;

	int start = cell_particle_offsets[cell_id];
	int end = cell_particle_offsets[cell_id + 1];
	for (int i = start; i < end; i++) {
		int par_id = cell_particle_ids[i];
		particle_velocities[par_id] *= coef;
	}
}

void WorldState::change_velocity_by_area(float coef, Vector2i arr_pos) {
	int cell_id = arr_pos.x + arr_pos.y * cell_area.x;
	if (cell_id < 0 || cell_id >= cell_count) return;

	int neighbors_start = cell_neighbor_offsets[cell_id];
	int neighbors_end = cell_neighbor_offsets[cell_id + 1];
	for (int i = neighbors_start; i < neighbors_end; i++) {
		int neighbor_id = cell_neighbor_ids[i];
		if (neighbor_id < 0) continue;
		int particles_start = cell_particle_offsets[neighbor_id];
		int particles_end = cell_particle_offsets[neighbor_id + 1];
		for (int j = particles_start; j < particles_end; j++) {
			int par_id = cell_particle_ids[j];
			particle_velocities[par_id] *= coef;
		}
	}
}

void WorldState::set_particle_position_by_id(int id, Vector2 position) {
	if (id < 0 || id >= particle_positions.size()) return;
	particle_positions[id] = position;
}

void WorldState::set_particle_velocity_by_id(int id, Vector2 velocity) {
	if (id < 0 || id >= particle_velocities.size()) return;
	particle_velocities[id] = velocity;
}

void WorldState::set_particle_acceleration_by_id(int id, Vector2 acceleration) {
	if (id < 0 || id >= particle_accelerations.size()) return;
	particle_accelerations[id] = acceleration;
}


