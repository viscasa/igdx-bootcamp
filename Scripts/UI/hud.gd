class_name HUD extends Control

## Top bar, feedback line and help text, shared by both rooms.
## Reads GameState directly so it does not care which room it is in.

## Set by whichever room owns this HUD, e.g. "TAB — ke Dapur".
var room_hint: String = ""
## Per-room control hints, drawn under the shared line.
var help_lines: PackedStringArray = PackedStringArray()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(
		func() -> void: set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT))


func _draw() -> void:
	var font := ThemeDB.fallback_font
	_draw_top_bar(font)
	_draw_feedback(font)
	_draw_help(font)

	if GameState.game_over:
		_draw_game_over(font)


func _draw_top_bar(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 42)), Color("1d1a16"))

	var mins := int(GameState.time_left) / 60
	var secs := int(GameState.time_left) % 60

	draw_string(font, Vector2(16, 28), "HARI %d" % GameState.day,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e8dcc0"))

	var clock_col := Color("e05a4f") if GameState.time_left < 30.0 else Color("ffd36f")
	draw_string(font, Vector2(110, 28), "%02d:%02d" % [mins, secs],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, clock_col)

	# Which room we are standing in, and how to leave it.
	draw_string(font, Vector2(186, 28), Rooms.display_name(Rooms.current),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("c9b892"))
	if room_hint != "":
		draw_string(font, Vector2(258, 28), room_hint,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("7a6f60"))

	draw_string(font, Vector2(400, 28), "Duit: %d" % GameState.day_earnings,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e8dcc0"))
	draw_string(font, Vector2(508, 28), "Total: %d" % GameState.money,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("9a8f80"))

	var rx := 634.0
	draw_string(font, Vector2(rx, 28), "Reputasi:", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color("9a8f80"))
	for i in range(10):
		draw_rect(Rect2(Vector2(rx + 68 + i * 13, 15), Vector2(9, 12)),
			Color("e05a4f") if i < GameState.reputation else Color("3a332c"))

	# Queue pressure is visible from either room — the player should never
	# be surprised by someone walking out while they were in the kitchen.
	var qx := rx + 210
	draw_string(font, Vector2(qx, 28), "Antre: %d" % GameState.queue.size(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("9a8f80"))

	var worst := 1.0
	for o in GameState.queue:
		worst = minf(worst, o.patience_ratio())
	if not GameState.queue.is_empty() and worst < 0.35:
		draw_string(font, Vector2(qx + 74, 28), "! ada yang hampir pergi",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e05a4f"))


func _draw_feedback(font: Font) -> void:
	var text := GameState.feedback_text()
	if text == "":
		return
	draw_string(font, Vector2(20, size.y - 54), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, GameState.feedback_color())


func _draw_help(font: Font) -> void:
	var y := size.y - 32
	for line in help_lines:
		draw_string(font, Vector2(20, y), line,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("7a6f60"))
		y += 14


func _draw_game_over(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.75))
	draw_string(font, Vector2(size.x / 2 - 90, size.y / 2 - 20), "KEDAI TUTUP",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("e05a4f"))
	draw_string(font, Vector2(size.x / 2 - 130, size.y / 2 + 16),
		"Bertahan %d hari · Total %d duit" % [GameState.day, GameState.money],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("e8dcc0"))
	draw_string(font, Vector2(size.x / 2 - 96, size.y / 2 + 48),
		"Tekan tombol apa saja untuk ulang", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color("9a8f80"))
