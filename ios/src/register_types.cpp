// Copyright (c) Tenjin. All Rights Reserved.

#include "register_types.h"

#ifndef TENJIN_STUB
#include "tenjin_ios.h"
#endif

#include <gdextension_interface.h>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

// TENJIN_STUB builds (the macOS editor library) register nothing, so the
// GDScript wrapper finds no "TenjinSDK" singleton and every call is a no-op.

#ifndef TENJIN_STUB
static TenjinIOS *tenjin_singleton = nullptr;
#endif

void initialize_tenjin_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
#ifndef TENJIN_STUB
	GDREGISTER_CLASS(TenjinIOS);
	tenjin_singleton = memnew(TenjinIOS);
	Engine::get_singleton()->register_singleton("TenjinSDK", tenjin_singleton);
#endif
}

void uninitialize_tenjin_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
#ifndef TENJIN_STUB
	Engine::get_singleton()->unregister_singleton("TenjinSDK");
	memdelete(tenjin_singleton);
	tenjin_singleton = nullptr;
#endif
}

extern "C" {

// Entry symbol referenced by addons/tenjin/tenjin.gdextension.
GDExtensionBool GDE_EXPORT tenjin_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address,
		const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

	init_obj.register_initializer(initialize_tenjin_module);
	init_obj.register_terminator(uninitialize_tenjin_module);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}
