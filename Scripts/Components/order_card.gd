class_name OrderCard extends Node2D

var orders: Array[Order] = []
var supplied: Dictionary = {}
var mix_cost: int = 0
var heritage_preview: String = ""


func _ready() -> void:
	set_process(true)
	_sync_visuals()


func _process(_delta: float) -> void:
	_sync_visuals()


func _sync_visuals() -> void:
	if not is_inside_tree():
		return
	var empty := get_node_or_null("EmptyHint") as Label
	var summary := get_node_or_null("Summary") as Label
	var entries := get_node_or_null("Entries") as VBoxContainer
	if empty == null or summary == null or entries == null:
		return
	empty.visible = orders.is_empty()
	summary.visible = not orders.is_empty()
	if supplied.is_empty():
		summary.text = "KUALI KOSONG"
	else:
		summary.text = "BIAYA  %d%s" % [mix_cost, "   ★ %s" % heritage_preview if heritage_preview != "" else ""]
	for i in range(entries.get_child_count()):
		var entry := entries.get_child(i) as OrderEntry
		entry.visible = i < orders.size()
		if i < orders.size():
			entry.bind(orders[i], supplied)
