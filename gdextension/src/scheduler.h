#ifndef SCHEDULER_H
#define SCHEDULER_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <vector>
#include "world_state.h"
#include "movement_handler.h"
#include "chunk.h"


namespace godot {
	class Scheduler : public RefCounted {
		GDCLASS(Scheduler, RefCounted)
	private:
		int chunk_count{};
		int chunk_size = 1;
		float max_chunk_time_usec{};
		float time_step{};
		std::vector<Ref<Chunk>> chunks;
		Ref<MovementHandler> movement_handler;
		Ref<WorldState> world_state;
	
	protected:
		static void _bind_methods();

	public:
		Scheduler();
		~Scheduler();

		void setup(const Ref<WorldState>& world_state, const Object* globals);
		void set_globals(const Object* globals);
		void step(float delta_t);
		void first_multithreaded_step(int chunk_iter);
		void second_multithreaded_step(int chunk_iter);
		void assign_chunks();
		void update_chunk_size();
		void process_chunks();
		void prepare_chunk(Ref<Chunk>& chunk);


	};
}

#endif // !SCHEDULER_H

