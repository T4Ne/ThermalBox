#include "register_types.h"
#include "simple.h" // Import your class header here
#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_simple_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
    // Register the class so Godot knows it exists
    ClassDB::register_class<SimpleNode>();
}

void uninitialize_simple_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
}

extern "C" {
    GDExtensionBool GDE_EXPORT simple_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization* r_initialization) {
        godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

        init_obj.register_initializer(initialize_simple_module);
        init_obj.register_terminator(uninitialize_simple_module);

        // REMOVED: init_obj.set_min_library_initialization_level(...) 
        // This line is not needed for this test and causes errors on some versions.

        return init_obj.init();
    }
}