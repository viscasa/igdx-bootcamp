class_name Potion extends Node2D

## The physical bottle the player carries: kuali -> panci -> customer.
## Drawn with primitives; the liquid colour comes from its ingredients.

const W := 40
const H := 56

var brew: Brew
var lifted: bool = false
## The pot draws its own status text, so the bottle hides its name label
## there to avoid overlapping it.
var compact: bool = false


func setup(b: Brew) -> void:
	brew = b
	queue_redraw()


## Slightly larger than the drawn bottle so it is comfortable to grab.
func rect() -> Rect2:
	return Rect2(Vector2(-W * 0.5 - 4, -H - 12), Vector2(W + 8, H + 24))


func hits(global_pos: Vector2) -> bool:
	return rect().has_point(to_local(global_pos))


func set_lifted(v: bool) -> void:
	lifted = v
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2.ONE * (1.12 if v else 1.0), 0.1)
	queue_redraw()


func _draw() -> void:
	if brew:
		draw_bottle(self, Vector2.ZERO, brew, 1.0, lifted, not compact)


## Draws a bottle onto any CanvasItem at `at`.
##
## Shared as a static so the counter and the carry shelf can render brews
## the player is holding without spawning throwaway Potion nodes for them.
static func draw_bottle(ci: CanvasItem, at: Vector2, b: Brew,
		scale_: float = 1.0, shadow: bool = false, with_label: bool = true) -> void:
	if b == null:
		return

	var w := W * scale_
	var h := H * scale_

	var liquid := b.color()
	if b.is_burnt:
		liquid = Color("3a2e24")

	if shadow:
		ci.draw_rect(Rect2(at + Vector2(-w * 0.5 + 3, -h + 5), Vector2(w, h)),
			Color(0, 0, 0, 0.25))

	# Neck
	ci.draw_rect(Rect2(at + Vector2(-5 * scale_, -h), Vector2(10 * scale_, 10 * scale_)),
		Color("6a6155"))
	# Cork
	ci.draw_rect(Rect2(at + Vector2(-6 * scale_, -h - 5 * scale_),
		Vector2(12 * scale_, 6 * scale_)), Color("8a6a3c"))

	# Body
	var body := Rect2(at + Vector2(-w * 0.5, -h + 10 * scale_), Vector2(w, h - 10 * scale_))
	ci.draw_rect(body, Color("1a1712"))

	# Liquid fills from the bottom as it cooks — doubles as a progress read.
	var fill := clampf(b.doneness, 0.15, 1.0)
	var lh := (body.size.y - 4) * fill
	ci.draw_rect(Rect2(Vector2(body.position.x + 2, body.end.y - 2 - lh),
		Vector2(body.size.x - 4, lh)), liquid)

	# Glass highlight
	ci.draw_rect(Rect2(Vector2(body.position.x + 4, body.position.y + 4),
		Vector2(3, body.size.y - 12)), Color(1, 1, 1, 0.18))

	ci.draw_rect(body, Color("4a4038"), false, 2.0)

	# Status pip: green = ready, red = burnt.
	if b.is_burnt:
		ci.draw_circle(at + Vector2(0, -h - 10 * scale_), 4.0, Color("e05a4f"))
	elif b.is_done:
		ci.draw_circle(at + Vector2(0, -h - 10 * scale_), 4.0, Color("6fd48f"))

	# Symptom swatches: what this bottle actually treats. Without these the
	# player would have to remember every bottle they are carrying.
	var treats := b.treats()
	if not treats.is_empty():
		var tw := treats.size() * 11 - 3
		var tx := at.x - tw * 0.5
		for s in treats:
			ci.draw_rect(Rect2(Vector2(tx, at.y + 3), Vector2(8, 5)), Symptom.color(s))
			tx += 11

	# Who it was mixed for — a reminder, not a restriction.
	if b.intended_for and with_label:
		ci.draw_string(ThemeDB.fallback_font, at + Vector2(-40, 20),
			b.intended_for.display_name, HORIZONTAL_ALIGNMENT_CENTER, 80, 9,
			Color("7a6f60"))
