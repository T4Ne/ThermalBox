#include "scheduler.h"
#include <godot_cpp/classes/worker_thread_pool.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <cmath>

using namespace godot;

void Scheduler::_bind_methods(){
	ClassDB::bind_method(D_METHOD("step"), &Scheduler::step);
	ClassDB::bind_method(D_METHOD("setup"), &Scheduler::setup);
	ClassDB::bind_method(D_METHOD("first_multithreaded_step"), &Scheduler::first_multithreaded_step);
	ClassDB::bind_method(D_METHOD("second_multithreaded_step"), &Scheduler::second_multithreaded_step);
}

Scheduler::Scheduler() {
	movement_handler.instantiate();
}

godot::Scheduler::~Scheduler() {
}

void Scheduler::setup(const Ref<WorldState>& world_state, const Dictionary& config) {
	Scheduler::world_state = world_state;
	set_globals(config);
}

void Scheduler::set_globals(const Dictionary& config) {
	max_chunk_time_usec = config["min_chunk_time_usec"];
	movement_handler->set_globals(config);
}

void Scheduler::step(float delta_t) {
	if (world_state->get_particle_count() <= 0) return;
	time_step = delta_t;
	world_state->build_cell_map();
	update_chunk_size();
	assign_chunks();
	if (chunk_count > 0) {
		WorkerThreadPool* pool = WorkerThreadPool::get_singleton();
		int group_id = pool->add_group_task(Callable(this, "first_multithreaded_step"), chunk_count);
		pool->wait_for_group_task_completion(group_id);
		
		process_chunks();
		/* Experimental: not mapping particles to new cells in the middle of a step. 
		world_state->build_cell_map();
		update_chunk_size();
		assign_chunks();
		*/

		group_id = pool->add_group_task(Callable(this, "second_multithreaded_step"), chunk_count);
		pool->wait_for_group_task_completion(group_id);
		
		process_chunks();
	}

}

void Scheduler::first_multithreaded_step(int chunk_iter) {
	Ref<Chunk>& chunk = chunks[chunk_iter];
	uint64_t start = Time::get_singleton()->get_ticks_usec();
	prepare_chunk(chunk);
	movement_handler->first_half_verlet(time_step, world_state, chunk);
	uint64_t end = Time::get_singleton()->get_ticks_usec();
	chunk->set_execution_time(end - start);
}

void Scheduler::second_multithreaded_step(int chunk_iter) {
	Ref<Chunk>& chunk = chunks[chunk_iter];
	uint64_t start = Time::get_singleton()->get_ticks_usec();
	movement_handler->second_half_verlet(time_step, world_state, chunk);
	uint64_t end = Time::get_singleton()->get_ticks_usec();
	chunk->set_execution_time(end - start);
}

void Scheduler::assign_chunks() {
	int current_idx = 0;
	int occup_cell_count = world_state->get_occupied_cell_count();
	
	if (chunk_size > 0) {
		chunk_count = (int)std::ceil((double)occup_cell_count / (double)chunk_size);
	}
	else {
		chunk_count = 1;
	}
	
	if (chunk_count == 0) chunk_count = 1;
	
	if (chunks.size() < chunk_count) {
		chunks.resize(chunk_count);
		for (int i = 0; i < chunks.size(); i++) {
			if (chunks[i].is_null()) chunks[i].instantiate();
		}
	}
	else if (chunks.size() > chunk_count) {
		chunks.resize(chunk_count);
	}

	int chunk_idx = 0;
	while (current_idx < occup_cell_count) {
		int chunk_end = current_idx + chunk_size;
		if (chunk_end > occup_cell_count) {
			chunk_end = occup_cell_count;
		}
		chunks[chunk_idx]->setup(current_idx, chunk_end);
		chunk_idx++;
		current_idx = chunk_end;

	}
}

void Scheduler::update_chunk_size() {
	float max_time = 0.0;
	
	for (int chunk_idx = 0; chunk_idx < chunks.size(); chunk_idx++) {
		Ref<Chunk>& chunk = chunks[chunk_idx];
		float chunk_time = chunk->get_execution_time();
		if (chunk_time > max_time) {
			max_time = chunk_time;
		}
	}
	if (max_time == 0.0) return;

	float chunk_time_factor = max_chunk_time_usec / max_time;
	int new_chunk_size = UtilityFunctions::roundi(chunk_size * UtilityFunctions::lerpf(1.0, chunk_time_factor, 0.3));
	chunk_size = UtilityFunctions::clampi(new_chunk_size, 1, world_state->get_occupied_cell_count());

}

void Scheduler::process_chunks() {
	PackedVector2Array& world_positions = world_state->get_particle_positions_mut();
	PackedVector2Array& world_velocities = world_state->get_particle_velocities_mut();
	PackedVector2Array& world_accelerations = world_state->get_particle_accelerations_mut();
	Vector2* world_pos_ptr = world_positions.ptrw();
	Vector2* world_vel_ptr = world_velocities.ptrw();
	Vector2* world_accel_ptr = world_accelerations.ptrw();

	for (int chunk_idx = 0; chunk_idx < chunks.size(); chunk_idx++) {
		Ref<Chunk>& chunk = chunks[chunk_idx];
		int chunk_par_count = chunk->get_particle_count();
		
		const PackedInt32Array& chunk_ids = chunk->get_particle_ids();
		const PackedVector2Array& chunk_positions = chunk->get_positions();
		const PackedVector2Array& chunk_velocities = chunk->get_velocities();
		const PackedVector2Array& chunk_accelerations = chunk->get_accelerations();
		const int32_t* chunk_ids_ptr = chunk_ids.ptr();
		const Vector2* chunk_pos_ptr = chunk_positions.ptr();
		const Vector2* chunk_vel_ptr = chunk_velocities.ptr();
		const Vector2* chunk_accel_ptr = chunk_accelerations.ptr();
		
		for (int par_idx = 0; par_idx < chunk_ids.size(); par_idx++) {
			int par_id = chunk_ids_ptr[par_idx];
			world_pos_ptr[par_id] = chunk_pos_ptr[par_idx];
			world_vel_ptr[par_id] = chunk_vel_ptr[par_idx];
			world_accel_ptr[par_id] = chunk_accel_ptr[par_idx];
		}
	}
}

void Scheduler::prepare_chunk(Ref<Chunk>& chunk) {
	int cell_start = chunk->get_cell_start();
	int cell_end = chunk->get_cell_end();
	const PackedInt32Array& occup_cell_ids = world_state->get_occupied_cell_ids();
	const PackedInt32Array& cell_particle_offsets = world_state->get_cell_particle_offsets();
	const PackedInt32Array& cell_particle_ids = world_state->get_cell_particle_ids();
	const int32_t* occup_cell_ids_ptr = occup_cell_ids.ptr();
	const int32_t* cell_par_offset_ptr = cell_particle_offsets.ptr();
	const int32_t* cell_par_ids_ptr = cell_particle_ids.ptr();
	int par_count = 0;

	for (int occup_idx = cell_start; occup_idx < cell_end; occup_idx++) {
		int cell_id = occup_cell_ids_ptr[occup_idx];
		int particle_ids_start = cell_par_offset_ptr[cell_id];
		int particle_ids_end = cell_par_offset_ptr[cell_id + 1];
		for (int offset_idx = particle_ids_start; offset_idx < particle_ids_end; offset_idx++) {
			int par_id = cell_par_ids_ptr[offset_idx];
			chunk->push_particle_id(par_id);
			par_count++;
		}
	}
	chunk->resize_buffers(par_count);
	chunk->set_particle_count(par_count);
}
