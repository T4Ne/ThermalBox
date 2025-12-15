#include "movement_handler.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <vector>
#include <cmath>


using namespace godot;

void MovementHandler::_bind_methods() {
}

MovementHandler::MovementHandler() {
}

MovementHandler::~MovementHandler() {
}

void MovementHandler::setup(const Dictionary& config) {
	set_globals(config);
}

void MovementHandler::set_globals(const Dictionary& config) {
	max_speed = config["max_speed"];
	max_speed_sq = pow(max_speed, 2);
	interaction_range_r = config["interaction_range_r"];
	interaction_range_sq = pow(interaction_range_r * (float)config["default_particle_radius"], 2);
	wall_thermal_coef = config["wall_thermal_coef"];
	wall_thermal_coef_inv = 1.0 / (double)wall_thermal_coef;
	pump_acceleration = config["pump_acceleration"];
	pump_max_speed = config["pump_max_speed"];
	max_acceleration = config["max_accel"];
	max_acceleration_sq = pow(max_acceleration, 2);
	gravity_is_on = config["gravity_is_on"];
	gravity = config["gravity"];
	build_interaction_list(config);
}

void MovementHandler::build_interaction_list(const Dictionary& config) {
	interaction_list.clear();
	interaction_list.resize(particle_type_count * particle_type_count * inter_param_count);
	float* interaction_ptr = interaction_list.data();
	for (int idx = 0; idx < particle_type_count * particle_type_count; idx++) {
		int type_1 = idx / particle_type_count;
		int type_2 = idx % particle_type_count;
		if (type_1 > type_2) {
			int temp = type_1;
			type_1 = type_2;
			type_2 = temp;
		}
		InterTypes inter_type = WEAK_REPULSION;
		if (type_1 == 0) {
			if (type_2 == 0) inter_type = WEAK_LENNARD_JONES;
			else if (type_2 == 1) inter_type = STRONG_LENNARD_JONES;
			else if (type_2 == 2) inter_type = WEAK_LENNARD_JONES;
		}
		else if (type_1 == 1) {
			if (type_2 == 1) inter_type = STRONG_REPULSION;
		}
		/* 
		interactions by particle type:
		0 - 0: WEAKINTER
		0 - 1: STRONGINTER
		0 - 2: WEAKINTER
		0 - 3: WEAKREPUL
		1 - 1: STRONGREPUL
		1 - 2: WEAKREPUL
		1 - 3: WEAKREPUL
		2 - 2: WEAKREPUL
		2 - 3: WEAKREPUL
		3 - 3: WEAKREPUL
		*/
		Array params;
		switch (inter_type) {
		case WEAK_LENNARD_JONES:
			params = config["weak_lennard"];
			break;
		case STRONG_LENNARD_JONES:
			params = config["strong_lennard"];
			break;
		case WEAK_REPULSION:
			params = config["weak_repul"];
			break;
		case STRONG_REPULSION:
			params = config["strong_repul"];
			break;
		}
		int write_pos = idx * inter_param_count;
		interaction_ptr[write_pos + 0] = (float)params[0];
		interaction_ptr[write_pos + 1] = (float)params[1];
		interaction_ptr[write_pos + 2] = (float)inter_type;
	}
}

void MovementHandler::first_half_verlet(float time_step, const Ref<WorldState>& world_state, Ref<Chunk>& chunk) {
	int chunk_particle_count = chunk->get_particle_count();
	const PackedInt32Array& chunk_particle_ids = chunk->get_particle_ids();
	const PackedVector2Array& old_particle_positions = world_state->get_particle_positions();
	const PackedVector2Array& old_particle_velocities = world_state->get_particle_velocities();
	const PackedVector2Array& old_particle_accelerations = world_state->get_particle_accelerations();
	const int32_t* id_ptr = chunk_particle_ids.ptr();
	const Vector2* old_pos_ptr = old_particle_positions.ptr();
	const Vector2* old_vel_ptr = old_particle_velocities.ptr();
	const Vector2* old_accel_ptr = old_particle_accelerations.ptr();
	PackedVector2Array& new_particle_positions = chunk->get_positions_mut();
	PackedVector2Array& new_particle_velocities = chunk->get_velocities_mut();
	PackedVector2Array& new_particle_accelerations = chunk->get_accelerations_mut();
	Vector2* new_pos_ptr = new_particle_positions.ptrw();
	Vector2* new_vel_ptr = new_particle_velocities.ptrw();
	Vector2* new_accel_ptr = new_particle_accelerations.ptrw();


	for (int par_idx = 0; par_idx < chunk_particle_count; par_idx++) {
		int par_id = id_ptr[par_idx];
		const Vector2 old_position = old_pos_ptr[par_id];
		const Vector2 old_velocity = old_vel_ptr[par_id];
		const Vector2 old_acceleration = old_accel_ptr[par_id];

		// Velocity verlet step 1: half step velocity
		Vector2 half_step_velocity = old_velocity + old_acceleration * time_step * 0.5;
		if (half_step_velocity.length_squared() > max_speed_sq) {
			half_step_velocity = half_step_velocity.normalized() * max_speed;
		}
		// Velocity verlet step 2: full step position
		const Vector2 full_step_position = old_position + half_step_velocity * time_step;

		new_pos_ptr[par_idx] = full_step_position;
		new_vel_ptr[par_idx] = half_step_velocity;
		new_accel_ptr[par_idx] = old_acceleration;
	}

}

void MovementHandler::second_half_verlet(float time_step, const Ref<WorldState>& world_state, Ref<Chunk>& chunk) {
	int chunk_particle_count = chunk->get_particle_count();
	const PackedInt32Array& chunk_particle_ids = chunk->get_particle_ids();
	const PackedVector2Array& old_particle_positions = world_state->get_particle_positions();
	const PackedVector2Array& old_particle_velocities = world_state->get_particle_velocities();
	const int32_t* id_ptr = chunk_particle_ids.ptr();
	const Vector2* old_pos_ptr = old_particle_positions.ptr();
	const Vector2* old_vel_ptr = old_particle_velocities.ptr();
	PackedVector2Array& new_particle_positions = chunk->get_positions_mut();
	PackedVector2Array& new_particle_velocities = chunk->get_velocities_mut();
	PackedVector2Array& new_particle_accelerations = chunk->get_accelerations_mut();
	Vector2* new_pos_ptr = new_particle_positions.ptrw();
	Vector2* new_vel_ptr = new_particle_velocities.ptrw();
	Vector2* new_accel_ptr = new_particle_accelerations.ptrw();

	for (int par_idx = 0; par_idx < chunk_particle_count; par_idx++) {
		int par_id = id_ptr[par_idx];
		const Vector2 old_position = old_pos_ptr[par_id];
		const Vector2 old_velocity = old_vel_ptr[par_id];

		// Velocity verlet step 3: full step acceleration (with position offset from collisions)
		PackedVector2Array collision_values = calculate_collisions(time_step, par_id, old_position, old_velocity, world_state, chunk);
		Vector2 full_step_acceleration = collision_values[0];
		Vector2 updated_full_step_position = collision_values[1];

		if (full_step_acceleration.length_squared() > max_acceleration_sq) {
			full_step_acceleration = full_step_acceleration.normalized() * max_acceleration;
		}
		// Velocity verlet step 4: full step velocity
		Vector2 full_step_velocity = old_velocity + full_step_acceleration * time_step * 0.5;
		
		if (full_step_velocity.length_squared() > max_speed_sq) {
			full_step_velocity = full_step_velocity.normalized() * max_speed;
		}

		new_pos_ptr[par_idx] = updated_full_step_position;
		new_vel_ptr[par_idx] = full_step_velocity;
		new_accel_ptr[par_idx] = full_step_acceleration;
	}
}

Vector2 MovementHandler::interact_with_particles(int id, const Vector2 position, const PackedInt32Array& neighbor_cells, const Ref<WorldState>& world_state) {
	Vector2 accumulated_acceleration = Vector2(0.0, 0.0);
	const PackedVector2Array& particle_positions = world_state->get_particle_positions();
	const PackedByteArray& particle_types = world_state->get_particle_types();
	const PackedInt32Array& cell_offsets = world_state->get_cell_particle_offsets();
	const PackedInt32Array& cell_particle_ids = world_state->get_cell_particle_ids();
	int neighbor_count = world_state->get_neighbor_count();
	float radius = world_state->get_particle_radius();
	float mass = world_state->get_particle_masses()[id];
	int self_type = (int)world_state->get_particle_types()[id];
	const int32_t* neighbor_ptr = neighbor_cells.ptr();
	const int32_t* offset_ptr = cell_offsets.ptr();
	const int32_t* cell_par_ptr = cell_particle_ids.ptr();
	const uint8_t* par_types_ptr = particle_types.ptr();
	const Vector2* par_pos_ptr = particle_positions.ptr();
	const float* inter_ptr = interaction_list.data();

	for (int neighbor_idx = 0; neighbor_idx < neighbor_count; neighbor_idx++) {
		int cell_id = neighbor_ptr[neighbor_idx];

		if (cell_id == -1) continue;

		int start_idx = offset_ptr[cell_id];
		int end_idx = offset_ptr[cell_id + 1];
		for (int idx = start_idx; idx < end_idx; idx++) {
			int other_id = cell_par_ptr[idx];

			if (id == other_id) continue;

			int other_type = par_types_ptr[other_id];
			Vector2 other_position = par_pos_ptr[other_id];
			Vector2 other_to_self = other_position - position;
			float dist_sq = other_to_self.length_squared();

			if (dist_sq > interaction_range_sq) continue;

			Vector2 other_to_self_u = other_to_self.normalized();
			float dist_r = sqrt(dist_sq) / radius;
			int inter_memory_offset = (self_type * particle_type_count + other_type) * inter_param_count;
			float param_0 = inter_ptr[inter_memory_offset + 0];
			float param_1 = inter_ptr[inter_memory_offset + 1];
			int param_2 = (int)inter_ptr[inter_memory_offset + 2];
			float force{};
			if (param_2 == WEAK_LENNARD_JONES || param_2 == STRONG_LENNARD_JONES) {
				if (dist_r == 0.0) {
					force = -max_acceleration * mass;
				}
				else {
					float b_div_d = param_1 / dist_r;
					force = param_0 * (pow(b_div_d, 4) - 2 * pow(b_div_d, 2));
					force = UtilityFunctions::maxf(force, -max_acceleration * mass);
				}
			}
			else {
				if (dist_r == 0.0) {
					force = -max_acceleration * mass;
				}
				else {
					force = param_0 * (param_1 / dist_r - 1.0);
					force = UtilityFunctions::maxf(force, -max_acceleration * mass);
				}
			}
			accumulated_acceleration += other_to_self_u * (force / mass);
		}
	}
	if (accumulated_acceleration.length_squared() > max_acceleration_sq) {
		accumulated_acceleration = accumulated_acceleration.normalized() * max_acceleration;
	}
	return accumulated_acceleration;
}

PackedVector2Array MovementHandler::collide_with_walls(int id, float time_step, const Vector2 position, const Vector2 velocity, const PackedInt32Array& neighbor_cells, const Ref<WorldState>& world_state, const Ref<Chunk>& chunk) {
	Vector2 accumulated_acceleration = Vector2(0.0, 0.0);
	Vector2 new_position = position;
	float cell_side_len = world_state->get_cell_size();
	float particle_radius = world_state->get_particle_radius() * 1.2; // magic number to increase wall interaction range so the collisions look nicer
	float particle_radius_sq = pow(particle_radius, 2);
	const PackedByteArray& cell_types = world_state->get_cell_types();
	const PackedInt32Array& type_category_map = world_state->get_type_category_map();
	const PackedFloat32Array& conduc_energies = world_state->get_conductor_energies();
	const PackedFloat32Array& particle_masses = world_state->get_particle_masses();
	const Vector2i cell_area = world_state->get_cell_area();
	const uint8_t* types_ptr = cell_types.ptr();
	const int32_t* type_cat_ptr = type_category_map.ptr();
	const int32_t* neighbor_ptr = neighbor_cells.ptr();
	const int* iter_order_ptr = cell_iteration_order.data();
	bool was_in_pump = false;

	int center_cell_id = neighbor_ptr[4]; // NOTE: will not work for neighbor ranges over 1.

	if (center_cell_id >= 0) { // Checking center cell to see if it's a pump
		int center_type = types_ptr[center_cell_id];
		if (center_type != 0) {
			int center_cat = type_cat_ptr[center_type];
			if (center_cat == 2) {
				Vector2 pump_dir = Vector2(0.0, 0.0);
				switch (center_type) {
				case 4: // pump up
					pump_dir = Vector2(0.0, -1.0);
					break;
				case 5: // pump down
					pump_dir = Vector2(0.0, 1.0);
					break;
				case 6: // pump left
					pump_dir = Vector2(-1.0, 0.0);
					break;
				case 7: // pump right
					pump_dir = Vector2(1.0, 0.0);
					break;
				}
				float pump_dir_velocity = pump_dir.dot(velocity);
				if (pump_dir_velocity < pump_max_speed) {
					accumulated_acceleration += pump_dir * pump_acceleration;
				}
				was_in_pump = true;
			}
		}
	}

	for (int i = 0; i < neighbor_cells.size(); i++) {
		int iter_idx = iter_order_ptr[i];
		
		if (iter_idx == 4) continue;

		int cell_id = neighbor_ptr[iter_idx];
		if (cell_id < 0) continue; // neighbor is not a cell

		int cell_type = types_ptr[cell_id];
		if (cell_type == 0) continue; // cell type is 0, so it's an empty cell
		
		float cell_xf = (cell_id % cell_area.x) * cell_side_len;
		float cell_yf = (cell_id / cell_area.x) * cell_side_len;
		Vector2 wall_position = Vector2(cell_xf, cell_yf);
		
		float wall_closest_xf = (float)CLAMP(new_position.x, wall_position.x, wall_position.x + cell_side_len);
		float wall_closest_yf = (float)CLAMP(new_position.y, wall_position.y, wall_position.y + cell_side_len);
		Vector2 wall_to_particle = new_position - Vector2(wall_closest_xf, wall_closest_yf);
		
		float dist_to_wall_sq = wall_to_particle.length_squared();

		if (dist_to_wall_sq > particle_radius_sq) continue; // not in range to interact
		if (dist_to_wall_sq == 0.0f) continue;

		int cell_category = type_cat_ptr[cell_type];
		
		if (cell_category == 3) { // cell is a diode
			Vector2 diode_dir = Vector2(0.0, 0.0);
			switch (cell_type) {
			case 8: // diode up
				diode_dir = Vector2(0.0, -1.0);
				break;
			case 9: // diode down
				diode_dir = Vector2(0.0, 1.0);
				break;
			case 10: // diode left
				diode_dir = Vector2(-1.0, 0.0);
				break;
			case 11: // diode right
				diode_dir = Vector2(1.0, 0.0);
				break;
			}
			if (wall_to_particle.dot(diode_dir) <= 0.0f) continue; // particle is not against the diode.

			Vector2 wall_to_particle_u = wall_to_particle.normalized();
			float normal_velocity_mag = wall_to_particle_u.dot(velocity);
			
			if (normal_velocity_mag > 0.0f) continue; // particle is already moving away

			float penetration = particle_radius - sqrt(dist_to_wall_sq);
			new_position += wall_to_particle_u * penetration;
			accumulated_acceleration += -2 * (normal_velocity_mag / time_step) * wall_to_particle_u; // mirror normal velocity component to diode with acceleration
		}
		else if (cell_category == 1) { // cell is a wall
			Vector2 wall_to_particle_u = wall_to_particle.normalized();
			float normal_velocity_mag = wall_to_particle_u.dot(velocity);

			if (normal_velocity_mag > 0.0f) continue; // particle is already moving away

			float penetration = particle_radius - sqrt(dist_to_wall_sq);
			new_position += wall_to_particle_u * penetration;
			switch (cell_type) {
			case 1: // normal wall
				accumulated_acceleration += -2 * (normal_velocity_mag / time_step) * wall_to_particle_u; // mirror normal vel with accel
				break;
			case 2: // cold wall
				accumulated_acceleration += -2 * (normal_velocity_mag / time_step) * wall_to_particle_u * wall_thermal_coef; // mirror normal vel with accel
				break;
			case 3: // hot wall
				accumulated_acceleration += -2 * (normal_velocity_mag / time_step) * wall_to_particle_u * wall_thermal_coef_inv; // mirror normal vel with accel
				break;
			}
		}
		else if (cell_category == 5) { // cell is a conductor
			Vector2 wall_to_particle_u = wall_to_particle.normalized();
			float normal_velocity_mag = wall_to_particle_u.dot(velocity);
			
			if (normal_velocity_mag > 0.0f) continue; // particle is already moving away

			float penetration = particle_radius - sqrt(dist_to_wall_sq);
			new_position += wall_to_particle_u * penetration;

			float wall_temp = conduc_energies[cell_id];
			float particle_temp_equiv = normal_velocity_mag * normal_velocity_mag;
			float conductivity = 0.5f;

			float target_temp = particle_temp_equiv + conductivity * (wall_temp - particle_temp_equiv);
			float v_out_mag = sqrt(abs(target_temp));

			float mass = particle_masses[id];
			float energy_gained_par = 0.5f * mass * (v_out_mag * v_out_mag - particle_temp_equiv);

			chunk->push_conductor_info(cell_id, -energy_gained_par);

			float delta_v = normal_velocity_mag - v_out_mag;

			accumulated_acceleration += -1 * (delta_v / time_step) * wall_to_particle_u;
		}
	}
	if (gravity_is_on && !was_in_pump) {
		accumulated_acceleration += gravity;
	}
	PackedVector2Array ret_values = { accumulated_acceleration, new_position };
	return ret_values;
}

PackedVector2Array MovementHandler::calculate_collisions(float time_step, int id, const Vector2 position, const Vector2 velocity, const Ref<WorldState>& world_state, const Ref<Chunk>& chunk) {
	int cell_x = (int)std::floor(position.x * world_state->get_inverted_cell_size());
	int cell_y = (int)std::floor(position.y * world_state->get_inverted_cell_size());
	Vector2i cell_area = world_state->get_cell_area();
	if (cell_x < 0 || cell_x >= cell_area.x || cell_y < 0 || cell_y >= cell_area.y) {
		PackedVector2Array ret_values = { Vector2(0.0, 0.0), position };
		return ret_values;
	}
	 
	int cell_id = cell_x + cell_y * world_state->get_cell_area().x;
	
	int neighbor_count = world_state->get_neighbor_count();
	const PackedInt32Array& cell_neighbor_ids = world_state->get_cell_neighbor_ids();
	int neighbor_idx_start = world_state->get_cell_neighbor_offsets()[cell_id];
	PackedInt32Array neighbor_cells = cell_neighbor_ids.slice(neighbor_idx_start, neighbor_idx_start + neighbor_count);
	
	Vector2 new_acceleration = Vector2(0.0, 0.0);
	PackedVector2Array new_values = collide_with_walls(id, time_step, position, velocity, neighbor_cells, world_state, chunk);
	new_acceleration += new_values[0];
	Vector2 new_position = new_values[1];

	new_acceleration += interact_with_particles(id, position, neighbor_cells, world_state);
	
	PackedVector2Array ret_values = { new_acceleration, new_position };
	return ret_values;
}
