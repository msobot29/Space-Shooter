@tool
extends EditorPlugin

const GAME_HELPER_AUTOLOAD_NAME := "_mcp_game_helper"
const GAME_HELPER_AUTOLOAD_PATH := "res://addons/godot_ai/runtime/game_helper.gd"

const EditorLogger := preload("res://addons/godot_ai/runtime/editor_logger.gd")
const PluginReload := preload("res://addons/godot_ai/utils/plugin_reload.gd")
const ReleaseVerifier := preload("res://addons/godot_ai/utils/release_verifier.gd")
const UpdateInstaller := preload("res://addons/godot_ai/utils/update_installer.gd")
const LIVE_ADDON_ROOT := "res://addons/godot_ai"
const PLUGIN_CFG := "res://addons/godot_ai/plugin.cfg"
const MIN_GODOT_MAJOR := 4
const MIN_GODOT_MINOR := 0
const UNSUPPORTED_GODOT_MESSAGE := \
	"Godot AI v4 requires Godot 4.7 or newer in the 4.x line; plugin remains inactive."

const ServerLifecycleManager := preload("res://addons/godot_ai/utils/server_lifecycle.gd")
const PortResolver := preload("res://addons/godot_ai/utils/port_resolver.gd")
const ServerStateScript := preload("res://addons/godot_ai/utils/mcp_server_state.gd")
const TransportCapability := preload("res://addons/godot_ai/utils/transport_capability.gd")

const Connection := preload("res://addons/godot_ai/connection.gd")
const Dispatcher := preload("res://addons/godot_ai/dispatcher.gd")
const Telemetry := preload("res://addons/godot_ai/telemetry.gd")
const LogBuffer := preload("res://addons/godot_ai/utils/log_buffer.gd")
const GameLogBuffer := preload("res://addons/godot_ai/utils/game_log_buffer.gd")
const EditorLogBuffer := preload("res://addons/godot_ai/utils/editor_log_buffer.gd")
const SurfacedErrorTracker := preload("res://addons/godot_ai/utils/surfaced_error_tracker.gd")
const Dock := preload("res://addons/godot_ai/mcp_dock.gd")
const DebuggerPlugin := preload("res://addons/godot_ai/debugger/mcp_debugger_plugin.gd")
const VisionRoutingScript := preload("res://addons/godot_ai/vision_routing.gd")
const ExportPlugin := preload("res://addons/godot_ai/export/mcp_export_plugin.gd")
const ClientConfigurator := preload("res://addons/godot_ai/client_configurator.gd")
const CliExec := preload("res://addons/godot_ai/clients/_cli_exec.gd")
const ClientJobOwner := preload("res://addons/godot_ai/utils/client_job_owner.gd")
const UpdateManager := preload("res://addons/godot_ai/utils/update_manager.gd")
const WindowsPortReservation := preload("res://addons/godot_ai/utils/windows_port_reservation.gd")
const McpToolRegistry := preload("res://addons/godot_ai/custom_tools/mcp_tool_registry.gd")
const McpServiceLocator := preload("res://addons/godot_ai/custom_tools/mcp_service_locator.gd")

const HANDLERS_DIR := "res://addons/godot_ai/handlers/"

const STARTUP_TRACE_COUNTER_NAMES := [
	"powershell",
	"netstat",
	"netsh",
	"lsof",
	"http_status_probe",
	"server_command_discovery",
]

var _connection
var _dispatcher
var _telemetry
var _log_buffer
var _game_log_buffer
var _editor_log_buffer
var _surfaced_error_tracker
var _editor_logger: Logger
var _dock
var _debugger_plugin
var _vision_routing
var _export_plugin
var _custom_tool_registry
var _custom_tool_service_locator
var _client_jobs
var _update_manager
var _post_update_outcome: Dictionary = {}
var _post_update_replaced_version := ""
var _post_update_deferred := []
var _last_logged_block := ""
const POST_UPDATE_REPROBE_LIMIT := 10
var _post_update_reprobes_left := POST_UPDATE_REPROBE_LIMIT
var _post_update_retry_episode := 0
const POST_UPDATE_STALE_REPROBE_SECONDS := 10.0
const POST_UPDATE_STALE_REPROBE_LIMIT := 21
var _post_update_stale_reprobes_left := POST_UPDATE_STALE_REPROBE_LIMIT
const POST_UPDATE_REPLACEMENT_LIMIT := 3
var _post_update_replacements_left := POST_UPDATE_REPLACEMENT_LIMIT
var _update_swapped := false