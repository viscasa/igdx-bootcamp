class_name HUD extends Control

## Top bar, feedback line and help text. The customer queue lives in world
## space (CustomerQueue) so potions can be dropped onto people.

var game: Node2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(
		func() -> void: set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT))


func _draw() -> void:
	if not game:
		return

	var font := ThemeDB.fallback_font
	_draw_top_bar(font)
	_draw_feedback(font)
	_draw_help(font)

	if game.game_over:
		_draw_game_over(font)


func _draw_top_bar(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 42)), Color("1d1a16"))

	var mins := int(game.time_left) / 60
	var secs := int(game.time_left) % 60

	draw_string(font, Vector2(16, 28), "HARI %d" % game.day,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e8dcc0"))

	var clock_col := Color("e05a4f") if game.time_left < 30.0 else Color("ffd36f")
	draw_string(font, Vector2(120, 28), "%02d:%02d" % [mins, secs],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, clock_col)

	if game.is_reading:
		draw_string(font, Vector2(196, 28), "membaca…",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("6fd48f"))

	draw_string(font, Vector2(280, 28), "Duit: %d" % game.day_earnings,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e8dcc0"))
	draw_string(font, Vector2(400, 28), "Total: %d" % game.money,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("9a8f80"))

	var rx := 530.0
	draw_string(font, Vector2(rx, 28), "Reputasi:", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color("9a8f80"))
	var rep: int = game.reputation
	for i in range(10):
		draw_rect(Rect2(Vector2(rx + 68 + i * 13, 15), Vector2(9, 12)),
			Color("e05a4f") if i < rep else Color("3a332c"))


func _draw_feedback(font: Font) -> void:
	if game._feedback_timer <= 0.0:
		return
	var col: Color = game._feedback_color
	col.a = clampf(game._feedback_timer / 1.0, 0.0, 1.0)
	draw_string(font, Vector2(20, size.y - 58), game._last_feedback,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)


func _draw_help(font: Font) -> void:
	var l1 := "1. Seret bahan ke kuali sampai penuh   2. SPASI: jadikan jamu   " \
		+ "3. Seret botol ke PANCI   4. W/S: atur api   5. Seret botol ke PELANGGAN"
	var l2 := "R / klik-kanan: putar bahan · Q/E: ganti pesanan · TAB: baca (waktu melambat)"
	draw_string(font, Vector2(20, size.y - 34), l1,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8a8070"))
	draw_string(font, Vector2(20, size.y - 20), l2,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("6a6155"))


func _draw_game_over(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.75))
	draw_string(font, Vector2(size.x / 2 - 90, size.y / 2 - 20), "KEDAI TUTUP",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("e05a4f"))
	draw_string(font, Vector2(size.x / 2 - 130, size.y / 2 + 16),
		"Bertahan %d hari · Total %d duit" % [game.day, game.money],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("e8dcc0"))
	draw_string(font, Vector2(size.x / 2 - 96, size.y / 2 + 48),
		"Tekan tombol apa saja untuk ulang", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color("9a8f80"))
