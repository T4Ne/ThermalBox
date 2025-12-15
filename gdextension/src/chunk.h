#ifndef CHUNK_H
#define CHUNK_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>

namespace godot {
	class Chunk : public RefCounted {
		GDCLASS(Chunk, RefCounted)
	private:
		int cell_start{};
		int cell_end{};
		int particle_count{};
		float execution_time_usec{};
		PackedInt32Array particle_ids;
		PackedVector2Array positions;
		PackedVector2Array velocities;
		PackedVector2Array accelerations;
		PackedInt32Array conductor_ids;
		PackedFloat32Array conductor_energy_deltas;
	
	public:
		Chunk();
		~Chunk();
		
		void setup(int id_start, int id_end);
		void resize_buffers(int size);
		

		void set_execution_time(float time) { execution_time_usec = time; };
		float get_execution_time() const { return execution_time_usec; };

		void set_cell_start(int id) { cell_start = id; };
		int get_cell_start() const { return cell_start; };
		
		void set_cell_end(int id) { cell_end = id; };
		int get_cell_end() const { return cell_end; };
		
		void set_particle_count(int count) { particle_count = count; };
		int get_particle_count() const { return particle_count; };
		
		void set_particle_ids(const PackedInt32Array& p_ids) { particle_ids = p_ids; };
		void push_particle_id(int id);
		const PackedInt32Array& get_particle_ids() { return particle_ids; };
		PackedInt32Array& get_particle_ids_mut() { return particle_ids; };
		
		void set_positions(const PackedVector2Array& p_positions) { positions = p_positions; };
		const PackedVector2Array& get_positions() { return positions; };
		PackedVector2Array& get_positions_mut() { return positions; };
		
		void set_velocities(const PackedVector2Array& p_velocities) { velocities = p_velocities; };
		const PackedVector2Array& get_velocities() { return velocities; };
		PackedVector2Array& get_velocities_mut() { return velocities; };
		
		void set_accelerations(const PackedVector2Array& p_accelerations) { accelerations = p_accelerations; };
		const PackedVector2Array& get_accelerations() { return accelerations; };
		PackedVector2Array& get_accelerations_mut() { return accelerations; };

		const PackedInt32Array& get_conductor_ids() { return conductor_ids; };

		const PackedFloat32Array& get_conductor_energies() { return conductor_energy_deltas; };

		void push_conductor_info(int id, float delta);

	
	protected:
		static void _bind_methods();
	};
} // namespace godot



#endif // !CHUNK_H
