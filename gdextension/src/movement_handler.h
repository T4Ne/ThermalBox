#ifndef MOVEMENT_HANDLER_H
#define MOVEMENT_HANDLER_H

#include <godot_cpp/classes/ref_counted.hpp>
#include "world_state.h"
#include "chunk.h"
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <vector>


namespace godot {
	class MovementHandler : public RefCounted {
		GDCLASS(MovementHandler, RefCounted)
	
	private:
		bool gravity_is_on{};
		int particle_type_count = 4; // TODO: move this to globals
		int inter_param_count = 3; // TODO: move this to globals
		float max_speed{};
		float max_speed_sq{};
		float interaction_range_r{};
		float interaction_range_sq{};
		float wall_thermal_coef{};
		float pump_acceleration{};
		float pump_max_speed{};
		float max_acceleration{};
		float max_acceleration_sq{};
		double wall_thermal_coef_inv{};
		std::vector<float> interaction_list;
		std::vector<int> cell_iteration_order = { 1, 3, 5, 7, 0, 2, 4, 6, 8 };
		Vector2 gravity;

		enum InterTypes {
			WEAK_LENNARD_JONES, STRONG_LENNARD_JONES, WEAK_REPULSION, STRONG_REPULSION
		};

	protected:
		static void _bind_methods();

	public:
		MovementHandler();
		~MovementHandler();

		void setup(const Dictionary& config);

		void set_globals(const Dictionary& config);

		void build_interaction_list(const Dictionary& config);
		
		void first_half_verlet(float time_step, const Ref<WorldState> &world_state, Ref<Chunk> &chunk);
		
		void second_half_verlet(float time_step, const Ref<WorldState> &world_state, Ref<Chunk> &chunk);
		
		Vector2 interact_with_particles(int id, const Vector2 position, const PackedInt32Array &neighbor_cells, const Ref<WorldState> &world_state);
		
		PackedVector2Array collide_with_walls(int id, float time_step, const Vector2 position, const Vector2 velocity, const PackedInt32Array& neighbor_cells, const Ref<WorldState>& world_state, const Ref<Chunk>& chunk);
		
		PackedVector2Array calculate_collisions(float time_step, int id, const Vector2 position, const Vector2 velocity, const Ref<WorldState>& world_state, const Ref<Chunk>& chunk);
	};
} // namespace godot



#endif // !MOVEMENT_HANDLER_H

