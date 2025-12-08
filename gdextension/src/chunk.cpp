# include "chunk.h"
# include <godot_cpp/core/class_db.hpp>

using namespace godot;

Chunk::Chunk() {
}

Chunk::~Chunk() {
}

void Chunk::setup(int id_start, int id_end) {
	cell_id_start = id_start;
	cell_id_end = id_end;
}

void Chunk::resize_buffers(int size) {
	positions.resize(size);
	velocities.resize(size);
	accelerations.resize(size);
}

void Chunk::_bind_methods(){
}