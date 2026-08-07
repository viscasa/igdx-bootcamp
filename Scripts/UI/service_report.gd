class_name ServiceReportPanel extends PanelContainer

@onready var title_label: Label = %TitleLabel
@onready var lines_box: VBoxContainer = %LinesBox


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _process(_delta: float) -> void:
	var show := GameState.service_report_visible()
	if show != visible:
		visible = show
	if not show:
		return
	var report := GameState.service_report
	if report.is_empty():
		return
	title_label.text = report[0]
	for i in range(lines_box.get_child_count()):
		var label := lines_box.get_child(i) as Label
		label.text = report[i + 1] if i + 1 < report.size() else ""
