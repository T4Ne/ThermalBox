#include "simple.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void SimpleNode::_bind_methods() {
    // This tells Godot that "get_value" exists
    ClassDB::bind_method(D_METHOD("get_value"), &SimpleNode::get_value);
}

SimpleNode::SimpleNode() {
}

SimpleNode::~SimpleNode() {
}

int SimpleNode::get_value() {
    return 1;
}