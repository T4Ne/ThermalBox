#ifndef CHUNK_H
#define CHUNK_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>

namespace godot {
	class Chunk : public RefCounted {
	GDCLASS(Chunk, RefCounted)
	private:
	
		int cell_id_start{};
		int cell_id_end{};
		int particle_count{};
		PackedInt32Array particle_ids;
		PackedVector2Array positions;
		PackedVector2Array velocities;
		PackedVector2Array accelerations;
		float start_time_usec{};
		float end_time_usec{};
	
	public:
		Chunk();
		~Chunk();
		
		void setup(int id_start, int id_end);
		void resize_buffers(int size);
		

		void set_cell_id_start(const int id) { cell_id_start = id; }
		int get_cell_id_start() const { return cell_id_start; }
		
		void set_cell_id_end(const int id) { cell_id_end = id; }
		int get_cell_id_end() const { return cell_id_end; }
		
		void set_particle_count(const int count) { particle_count = count; }
		int get_particle_count() const { return particle_count; }
		
		void set_particle_ids(const PackedInt32Array& p_ids) { particle_ids = p_ids; }
		PackedInt32Array get_particle_ids() const { return particle_ids; }
		
		void set_positions(const PackedVector2Array& p_positions) { positions = p_positions; }
		PackedVector2Array get_positions() const { return positions; }
		
		void set_velocities(const PackedVector2Array& p_velocities) { velocities = p_velocities; }
		PackedVector2Array get_velocities() const { return velocities; }
		
		void set_accelerations(const PackedVector2Array& p_accelerations) { accelerations = p_accelerations; }
		PackedVector2Array get_accelerations() const { return accelerations; }
	
	protected:
		static void _bind_methods();
	};
}



#endif // !CHUNK_H
