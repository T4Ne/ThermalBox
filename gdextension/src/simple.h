#ifndef SIMPLE_H
#define SIMPLE_H

#include <godot_cpp/classes/node.hpp>

namespace godot {

    class SimpleNode : public Node {
        GDCLASS(SimpleNode, Node)

    protected:
        static void _bind_methods();

    public:
        SimpleNode();
        ~SimpleNode();

        int get_value();
    };

}

#endif