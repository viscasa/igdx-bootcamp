@tool
class_name UpgradeCard
extends Button

@export var card_title := "PIPISAN TAJAM":
	set(value):
		card_title = value
		_sync_preview()
@export var card_effect := "+1 PAKAI PIPISAN PER HARI":
	set(value):
		card_effect = value
		_sync_preview()
@export var card_icon: Texture2D:
	set(value):
		card_icon = value
		_sync_preview()

var _hover_tween: Tween


func _ready() -> void:
	pivot_offset = size * 0.5
	resized.connect(func(): pivot_offset = size * 0.5)
	_sync_preview()
	if not Engine.is_editor_hint():
		mouse_entered.connect(_set_hovered.bind(true))
		mouse_exited.connect(_set_hovered.bind(false))


func setup(level: int, cost: int, can_afford: bool, maxed := false) -> void:
	$Content/Box/PriceRow/Price.text = "MAKSIMAL" if maxed else "LV %d  ·  %d" % [level, cost]
	$Content/Box/PriceRow/CoinIcon.visible = not maxed
	disabled = not can_afford
	modulate = Color(1, 1, 1, 1) if can_afford else Color(0.62, 0.58, 0.5, 0.82)


func _sync_preview() -> void:
	if not is_node_ready():
		return
	$Content/Box/Icon.texture = card_icon
	$Content/Box/Title.text = card_title
	$Content/Box/Effect.text = card_effect


func _set_hovered(hovered: bool) -> void:
	if disabled:
		return
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_hover_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", Vector2(1.035, 1.035) if hovered else Vector2.ONE, 0.14)
