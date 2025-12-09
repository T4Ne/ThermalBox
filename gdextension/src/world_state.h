#ifndef WORLD_STATE_H
#define WORLD_STATE_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <vector>

namespace godot {
	class WorldState : public RefCounted {
		GDCLASS(WorldState, RefCounted)

	private:
		int particle_count{};
		int cell_count{};
		int wall_count{};
		int pump_count{};
		int diode_count{};
		int spawner_count{};
		int occupied_cell_count{};
		int neighbor_range{};
		int neighbor_count{};
		float cell_size{};
		float particle_radius{};
		double inverted_cell_size{};
		Vector2i cell_area;
		PackedByteArray particle_types;
		PackedByteArray cell_types;
		PackedInt32Array occupied_cell_ids;
		PackedInt32Array cell_particle_offsets;
		PackedInt32Array cell_particle_ids;
		PackedInt32Array cell_neighbor_offsets;
		PackedInt32Array cell_neighbor_ids;
		PackedFloat32Array particle_masses;
		PackedFloat32Array particle_mass_by_type;
		PackedVector2Array particle_positions;
		PackedVector2Array particle_velocities;
		PackedVector2Array particle_accelerations;
		std::vector<int> type_category_map;

		enum CellType {
			EMPTY, NORMWALL, COLDWALL, HOTWALL, PUMPUP, PUMPDOWN, PUMPLEFT, PUMPRIGHT,
			DIODEUP, DIODEDOWN, DIODELEFT, DIODERIGHT, SPAWNERNONE, SPAWNER1, SPAWNER2, SPAWNER3, SPAWNER4, DRAIN
		};
		enum CountCategory {
			CAT_NONE, CAT_WALL, CAT_PUMP, CAT_DIODE, CAT_SPAWNER
		};
	
	protected:
		static void _bind_methods();

	public:
		WorldState();
		~WorldState();

		void setup(const int size, const Vector2i area, const bool borders = true);
		void set_globals(const Object* globals);
		void build_neighbor_offsets();
		PackedInt32Array get_neighbor_cells(const int cell_id) const;
		void set_cell_state(Vector2i arr_pos, const int new_type);
		void update_count_by_category(const int category, const int change);
		void build_borders();
		void build_cell_map();
		void add_particle(const int type, const Vector2 position, const Vector2 velocity);
		void clear_particles();
		void delete_particle(const int id);
		void delete_particles_by_cell(const Vector2i arr_pos);
		void spawn_particles_from_spawners();

		int get_particle_count() const { return particle_count; };

		int get_cell_count() const { return cell_count; };

		int get_wall_count() const { return wall_count; };

		int get_pump_count() const { return pump_count; };
		
		int get_diode_count() const { return diode_count; };

		int get_spawner_count() const { return spawner_count; };

		float get_cell_size() const { return cell_size; };

		float get_particle_radius() const { return particle_radius; };

		double get_inverted_cell_size() const { return inverted_cell_size; };

		Vector2i get_cell_area() const { return cell_area; };

		PackedByteArray get_particle_types() const { return particle_types; };

		PackedByteArray get_cell_types() const { return cell_types; };

		PackedInt32Array get_occupied_cell_ids() const { return occupied_cell_ids; };

		PackedInt32Array get_cell_particle_offsets() const { return cell_particle_offsets; };

		PackedInt32Array get_cell_particle_ids() const { return cell_particle_ids; };

		PackedInt32Array get_cell_neighbor_offsets() const { return cell_neighbor_offsets; };

		PackedInt32Array get_cell_neighbor_ids() const { return cell_neighbor_ids; };

		PackedFloat32Array get_particle_masses() const { return particle_masses; };

		PackedVector2Array get_particle_positions() const { return particle_positions; };
		void set_particle_position_by_id(const int id, const Vector2 position);

		PackedVector2Array get_particle_velocities() const { return particle_velocities; };
		void set_particle_velocity_by_id(const int id, const Vector2 velocity);

		PackedVector2Array get_particle_accelerations() const { return particle_accelerations; };
		void set_particle_acceleration_by_id(const int id, const Vector2 acceleration);
	};
} // namespace godot


#endif // !WORLD_STATE_H