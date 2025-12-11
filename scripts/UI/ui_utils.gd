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
