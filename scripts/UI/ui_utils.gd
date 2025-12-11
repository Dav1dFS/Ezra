class_name UIUtils
extends RefCounted

static func fade_in(node: CanvasItem, duration := 0.3) -> Tween:
	node.visible = true
	var tween = node.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(node, "modulate:a", 1.0, duration)
	return tween

static func fade_out(node: CanvasItem, duration := 0.3, hide_after := true) -> Tween:
	var tween = node.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(node, "modulate:a", 0.0, duration)
	if hide_after and node is not ColorRect:
		tween.finished.connect(func(): node.visible = false)
	return tween

static func format_play_time(play_time: float) -> String:
	var total_seconds: int = int(play_time)
	var hours: float = total_seconds / 3600.0
	var minutes: float = (total_seconds % 3600) / 60.0
	var seconds: int = total_seconds % 60
	return "%02dh %02dm %02ds" % [hours, minutes, seconds]

static func update_fps_label(label: Label) -> void:
	if label and label.visible:
		label.text = str(Engine.get_frames_per_second()) + " FPS"
