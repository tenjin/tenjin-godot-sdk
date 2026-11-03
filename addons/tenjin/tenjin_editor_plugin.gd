@tool
extends EditorPlugin
## Registers the `Tenjin` autoload, the export plugin that wires the native
## SDKs into Android/iOS builds, and the addon's project settings.

const AUTOLOAD_NAME := "Tenjin"
const AUTOLOAD_PATH := "res://addons/tenjin/tenjin.gd"
const TenjinExportPlugin := preload("res://addons/tenjin/tenjin_export_plugin.gd")

var _export_plugin: EditorExportPlugin


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


func _enter_tree() -> void:
	TenjinExportPlugin.register_project_settings()
	_export_plugin = TenjinExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null
