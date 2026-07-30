class_name HUD extends Control

## Prototype HUD, drawn entirely in _draw() so there is no scene layout to
## maintain while the design is still moving.

var game: Node2D

const PANEL_W := 360


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Always span the viewport, whatever the scene file says.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(
		func() -> void: set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT))


func _draw() -> void:
	if not game:
		return

	var font := ThemeDB.fallback_font

	_draw_top_bar(font)
	_draw_order_panel(font)
	_draw_feedback(font)
	_draw_help(font)

	if game.game_over:
		_draw_game_over(font)


func _draw_top_bar(font: Font) -> void:
	var w := size.x
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, 42)), Color("1d1a16"))

	var mins := int(game.time_left) / 60
	var secs := int(game.time_left) % 60

	draw_string(font, Vector2(16, 28), "HARI %d" % game.day,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e8dcc0"))

	var clock_col := Color("e05a4f") if game.time_left < 30.0 else Color("ffd36f")
	draw_string(font, Vector2(120, 28), "%02d:%02d" % [mins, secs],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, clock_col)

	if game.is_reading:
		draw_string(font, Vector2(200, 28), "membaca…",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("6fd48f"))

	draw_string(font, Vector2(280, 28), "Duit: %d" % game.day_earnings,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e8dcc0"))
	draw_string(font, Vector2(400, 28), "Total: %d" % game.money,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("9a8f80"))

	# Reputation pips
	var rx := 530.0
	draw_string(font, Vector2(rx, 28), "Reputasi:", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color("9a8f80"))
	var rep: int = game.reputation
	for i in range(10):
		draw_rect(Rect2(Vector2(rx + 68 + i * 13, 15), Vector2(9, 12)),
			Color("e05a4f") if i < rep else Color("3a332c"))


func _draw_order_panel(font: Font) -> void:
	var x := size.x - PANEL_W - 16
	var y := 56.0

	draw_rect(Rect2(Vector2(x, y), Vector2(PANEL_W, size.y - y - 16)), Color("1d1a16"))
	draw_rect(Rect2(Vector2(x, y), Vector2(PANEL_W, size.y - y - 16)),
		Color("4a4038"), false, 2.0)

	draw_string(font, Vector2(x + 12, y + 22), "ANTREAN", HORIZONTAL_ALIGNMENT_LEFT,
		-1, 15, Color("c9b892"))

	if game.queue.is_empty():
		draw_string(font, Vector2(x + 12, y + 52), "(menunggu pelanggan…)",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("5a5048"))
		return

	var cy := y + 40.0
	for i in range(game.queue.size()):
		var o = game.queue[i]
		var active: bool = i == game.active_index
		var card_h := 138.0

		var card := Rect2(Vector2(x + 10, cy), Vector2(PANEL_W - 20, card_h))
		draw_rect(card, Color("262119") if active else Color("201c17"))
		if active:
			draw_rect(card, Color("ffd36f"), false, 2.0)

		# Portrait placeholder
		draw_rect(Rect2(card.position + Vector2(8, 8), Vector2(32, 32)),
			o.customer.color)

		draw_string(font, card.position + Vector2(48, 22), o.customer.display_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e8dcc0"))
		draw_string(font, card.position + Vector2(48, 38), o.customer.role,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("7a6f60"))

		# Patience
		var pb := Rect2(card.position + Vector2(8, 48), Vector2(card.size.x - 16, 8))
		draw_rect(pb, Color("15120f"))
		var ratio: float = o.patience_ratio()
		var pcol := Color("6fa84f")
		if ratio < 0.25:
			pcol = Color("e05a4f")
		elif ratio < 0.5:
			pcol = Color("d89b3c")
		draw_rect(Rect2(pb.position, Vector2(pb.size.x * ratio, pb.size.y)), pcol)

		# Dialogue — the actual puzzle. Wrapped by hand for the prototype.
		var lines := _wrap(o.dialogue(), 40)
		var ly := card.position.y + 74
		for line in lines:
			draw_string(font, Vector2(card.position.x + 8, ly), line,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("c9c0ae"))
			ly += 14

		# Symptom chips (the answer key — hideable on hard mode)
		var sx := card.position.x + 8
		var sy := card.position.y + card_h - 12
		for s in o.symptoms():
			var label := Symptom.display_name(s)
			var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 10
			draw_rect(Rect2(Vector2(sx, sy - 10), Vector2(w, 14)), Symptom.color(s))
			draw_string(font, Vector2(sx + 5, sy), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("15120f"))
			sx += w + 4

		cy += card_h + 6


func _draw_feedback(font: Font) -> void:
	if game._feedback_timer <= 0.0:
		return
	var alpha := clampf(game._feedback_timer / 1.0, 0.0, 1.0)
	var col: Color = game._feedback_color
	col.a = alpha
	draw_string(font, Vector2(20, size.y - 58), game._last_feedback,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)


func _draw_help(font: Font) -> void:
	var l1 := "Drag bahan ke kuali · R / klik-kanan: putar · SPASI: masukkan panci"
	var l2 := "W/S: atur api · klik panci atau 1-4: sajikan · Q/E: ganti pesanan · TAB: baca (waktu melambat)"
	draw_string(font, Vector2(20, size.y - 34), l1,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("6a6155"))
	draw_string(font, Vector2(20, size.y - 20), l2,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("6a6155"))


func _draw_game_over(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.75))
	var msg := "KEDAI TUTUP"
	draw_string(font, Vector2(size.x / 2 - 90, size.y / 2 - 20), msg,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("e05a4f"))
	draw_string(font, Vector2(size.x / 2 - 130, size.y / 2 + 16),
		"Bertahan %d hari · Total %d duit" % [game.day, game.money],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("e8dcc0"))
	draw_string(font, Vector2(size.x / 2 - 90, size.y / 2 + 48),
		"Tekan tombol apa saja untuk ulang", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color("9a8f80"))


## Crude word wrap — good enough while the layout is still provisional.
func _wrap(text: String, width: int) -> Array[String]:
	var out: Array[String] = []
	var line := ""
	for word in text.split(" "):
		if line.length() + word.length() + 1 > width:
			out.append(line)
			line = word
		else:
			line = word if line.is_empty() else line + " " + word
	if not line.is_empty():
		out.append(line)
	return out
