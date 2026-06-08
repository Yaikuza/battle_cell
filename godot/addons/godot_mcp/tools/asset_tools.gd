@tool
extends Node
class_name AssetTools

var _editor_plugin: EditorPlugin = null

func set_editor_plugin(plugin: EditorPlugin) -> void:
	_editor_plugin = plugin

func _refresh_filesystem() -> void:
	if _editor_plugin:
		_editor_plugin.get_editor_interface().get_resource_filesystem().scan()

func generate_2d_asset(args: Dictionary) -> Dictionary:
	var svg_code: String = str(args.get(&"svg_code", ""))
	var filename: String = str(args.get(&"filename", ""))
	var save_path: String = str(args.get(&"save_path", "res://assets/generated/"))

	if svg_code.strip_edges().is_empty():
		return {&"ok": false, &"error": "Missing 'svg_code'"}
	if filename.strip_edges().is_empty():
		return {&"ok": false, &"error": "Missing 'filename'"}

	if not filename.ends_with(".png"):
		filename += ".png"

	if not save_path.begins_with("res://"):
		save_path = "res://" + save_path
	if not save_path.ends_with("/"):
		save_path += "/"

	if not DirAccess.dir_exists_absolute(save_path):
		DirAccess.make_dir_recursive_absolute(save_path)

	var width := 64
	var height := 64

	var w_start := svg_code.find("width=\"")
	if w_start != -1:
		var w_val := svg_code.substr(w_start + 7)
		var w_end := w_val.find("\"")
		if w_end != -1:
			width = int(w_val.substr(0, w_end))

	var h_start := svg_code.find("height=\"")
	if h_start != -1:
		var h_val := svg_code.substr(h_start + 8)
		var h_end := h_val.find("\"")
		if h_end != -1:
			height = int(h_val.substr(0, h_end))

	var image := Image.new()

	var temp_svg_path := "user://temp_asset.svg"
	var svg_file := FileAccess.open(temp_svg_path, FileAccess.WRITE)
	if not svg_file:
		return {&"ok": false, &"error": "Failed to create temp SVG file"}
	svg_file.store_string(svg_code)
	svg_file.close()

	var err := image.load(temp_svg_path)
	if err != OK:
		image = Image.create(width, height, false, Image.FORMAT_RGBA8)
		image.fill(Color(1, 0, 1, 1))
		print("[MCP] Warning: Could not render SVG, created fallback image")

	DirAccess.remove_absolute(temp_svg_path)

	var full_path := save_path + filename
	var global_path := ProjectSettings.globalize_path(full_path)
	err = image.save_png(global_path)
	if err != OK:
		return {&"ok": false, &"error": "Failed to save PNG: " + str(err)}

	_refresh_filesystem()

	return {
		&"ok": true,
		&"resource_path": full_path,
		&"dimensions": {&"width": width, &"height": height},
		&"message": "Generated %s (%dx%d)" % [full_path, width, height],
	}

func search_comfyui_nodes(args: Dictionary) -> Dictionary:
	return {
		&"ok": true,
		&"results": [],
		&"count": 0,
		&"message": "ComfyUI node search requires the node database. This feature will be available in a future update.",
	}

func inspect_runninghub_workflow(args: Dictionary) -> Dictionary:
	var workflow_id: String = str(args.get(&"workflow_id", ""))
	if workflow_id.strip_edges().is_empty():
		return {&"ok": false, &"error": "Missing 'workflow_id'"}

	return {
		&"ok": true,
		&"workflow_id": workflow_id,
		&"message": "RunningHub workflow inspection requires API configuration. This feature will be available in a future update.",
	}

func customize_and_run_workflow(args: Dictionary) -> Dictionary:
	return {
		&"ok": true,
		&"message": "RunningHub workflow execution requires API configuration. This feature will be available in a future update.",
	}
