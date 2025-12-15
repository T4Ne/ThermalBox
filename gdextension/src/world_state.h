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
		int conductor_count{};
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
		PackedInt32Array type_category_map;
		PackedFloat32Array conductor_energies;
		PackedFloat32Array particle_masses;
		Array particle_mass_by_type;
		PackedVector2Array particle_positions;
		PackedVector2Array particle_velocities;
		PackedVector2Array particle_accelerations;
		std::vector<int> deleted_particles;

		enum CellType {
			EMPTY, NORMWALL, COLDWALL, HOTWALL, PUMPUP, PUMPDOWN, PUMPLEFT, PUMPRIGHT,
			DIODEUP, DIODEDOWN, DIODELEFT, DIODERIGHT, SPAWNERNONE, SPAWNER1, SPAWNER2, SPAWNER3, SPAWNER4, DRAIN, CONDUCTOR
		};
		enum CountCategory {
			CAT_NONE, CAT_WALL, CAT_PUMP, CAT_DIODE, CAT_SPAWNER, CAT_CONDUCTOR
		};
	
	protected:
		static void _bind_methods();

	public:
		WorldState();
		~WorldState();

		void setup(bool borders, const Dictionary& config);
		void set_globals(const Dictionary& config);
		void build_neighbor_offsets();
		PackedInt32Array get_neighbor_cells(int cell_id) const;
		void set_cell_state(Vector2i arr_pos, int new_type);
		void update_count_by_category(int category, int change);
		void build_borders();
		void build_cell_map();
		void add_particle(int type, Vector2 position, Vector2 velocity);
		void clear_particles();
		void delete_particle(int id);
		void delete_particles_by_cell(Vector2i arr_pos);
		void spawn_particles_from_spawners();
		void change_velocity(float coef);

		int get_particle_count() const { return particle_count; };

		int get_cell_count() const { return cell_count; };

		int get_wall_count() const { return wall_count; };

		int get_pump_count() const { return pump_count; };
		
		int get_diode_count() const { return diode_count; };

		int get_spawner_count() const { return spawner_count; };

		int get_occupied_cell_count() const { return occupied_cell_count; };

		int get_neighbor_count() const { return neighbor_count; };

		int get_conductor_count() const { return conductor_count; };

		float get_cell_size() const { return cell_size; };

		float get_particle_radius() const { return particle_radius; };

		double get_inverted_cell_size() const { return inverted_cell_size; };

		Vector2i get_cell_area() const { return cell_area; };

		const PackedInt32Array& get_type_category_map() { return type_category_map; };

		const PackedByteArray& get_particle_types() { return particle_types; };

		const PackedByteArray& get_cell_types() { return cell_types; };

		const PackedInt32Array& get_occupied_cell_ids() { return occupied_cell_ids; };

		const PackedInt32Array& get_cell_particle_offsets() { return cell_particle_offsets; };

		const PackedInt32Array& get_cell_particle_ids() { return cell_particle_ids; };

		const PackedInt32Array& get_cell_neighbor_offsets() { return cell_neighbor_offsets; };

		const PackedInt32Array& get_cell_neighbor_ids() { return cell_neighbor_ids; };

		const PackedFloat32Array& get_particle_masses() { return particle_masses; };

		const PackedVector2Array& get_particle_positions() { return particle_positions; };
		PackedVector2Array& get_particle_positions_mut() { return particle_positions; };
		void set_particle_position_by_id(int id, Vector2 position);

		const PackedVector2Array& get_particle_velocities() { return particle_velocities; };
		PackedVector2Array& get_particle_velocities_mut() { return particle_velocities; };
		void set_particle_velocity_by_id(int id, Vector2 velocity);

		const PackedVector2Array& get_particle_accelerations() { return particle_accelerations; };
		PackedVector2Array& get_particle_accelerations_mut() { return particle_accelerations; };
		void set_particle_acceleration_by_id(int id, Vector2 acceleration);

		const PackedFloat32Array& get_conductor_energies() { return conductor_energies; };
		PackedFloat32Array& get_conductor_energies_mut() { return conductor_energies; };
	};
} // namespace godot


#endif // !WORLD_STATE_H