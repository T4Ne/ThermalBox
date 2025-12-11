# include "chunk.h"
# include <godot_cpp/core/class_db.hpp>

using namespace godot;

Chunk::Chunk() {
}

Chunk::~Chunk() {
}

void Chunk::setup(int start, int end) {
	cell_start = start;
	cell_end = end;
	particle_ids.clear();
	positions.clear();
	velocities.clear();
	accelerations.clear();

}

void Chunk::resize_buffers(int size) {
	positions.resize(size);
	velocities.resize(size);
	accelerations.resize(size);
}

void Chunk::push_particle_id(int id) {
	particle_ids.append(id);
}

void Chunk::_bind_methods(){
}