class_name DayTransition
extends Control

const IDS: Array[StringName] = [
	&"pipisan", &"heat", &"clean", &"patience", &"pay"
]

const EVENT_ICONS := {
	2: preload("res://Assets/UI/DaySummary/event_monsoon.svg"),
	3: preload("res://Assets/UI/DaySummary/event_market.svg"),
	4: preload("res://Assets/UI/DaySummary/event_travelers.svg"),
	5: preload("res://Assets/UI/DaySummary/event_inspection.svg"),
}

@onready var panel: Control = %Panel
@onready var eyebrow: Label = %Eyebrow
@onready var title_label: Label = %TitleLabel
@onready var served_card: SummaryStatCard = $Panel/Margin/Content/Stats/Served
@onready var perfect_card: SummaryStatCard = $Panel/Margin/Content/Stats/Perfect
@onready var reputation_card: SummaryStatCard = $Panel/Margin/Content/Stats/Reputation
@onready var money_card: SummaryStatCard = $Panel/Margin/Content/Stats/Money
@onready var stats: HBoxContainer = %Stats
@onready var forecast: Control = %Forecast
@onready var event_art: TextureRect = %EventArt
@onready var tomorrow_title: Label = %TomorrowTitle
@onready var tomorrow_description: Label = %TomorrowDescription
@onready var roster_label: Label = %RosterLabel
@onready var unlock: HBoxContainer = %Unlock
@onready var unlock_label: Label = %UnlockLabel
@onready var shop_column: VBoxContainer = %ShopColumn
@onready var upgrade_box: GridContainer = %UpgradeBox
@onready var continue_button: Button = %ContinueButton

var _last_phase: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	WorldAudioManager.set_button_cue(continue_button, WorldAudioManager.CONFIRM)
	GameState.phase_changed.connect(_refresh)
	for i in range(upgrade_box.get_child_count()):
		var button := upgrade_box.get_child(i) as UpgradeCard
		if button:
			WorldAudioManager.set_button_cue(button, &"")
			button.pressed.connect(_buy.bind(IDS[i]))
	continue_button.pressed.connect(_continue)
	_refresh()


func _refresh() -> void:
	var phase_is_new := _last_phase != int(GameState.phase)
	visible = GameState.phase != GameState.Phase.SHIFT
	get_tree().paused = visible
	if visible and phase_is_new:
		match GameState.phase:
			GameState.Phase.DAY_END:
				WorldAudioManager.play_ui(WorldAudioManager.MENU_OPEN)
			GameState.Phase.VICTORY:
				WorldAudioManager.play_ui(
					WorldAudioManager.SUCCESS, Vector2.ONE, -2.0, 1000)
			GameState.Phase.GAME_OVER:
				WorldAudioManager.play_ui(
					WorldAudioManager.FAILURE, Vector2.ONE, -2.0, 1000)
	_last_phase = int(GameState.phase)
	if not visible:
		return

	served_card.set_value("%d" % GameState.day_served)
	perfect_card.set_value("%d" % GameState.day_perfect)
	reputation_card.set_value("%d/10" % GameState.reputation)
	money_card.set_value("%d" % GameState.money)

	if GameState.phase == GameState.Phase.VICTORY:
		_show_run_end(true)
	elif GameState.phase == GameState.Phase.GAME_OVER:
		_show_run_end(false)
	else:
		_show_day_end()

	if phase_is_new:
		call_deferred("_animate_entry")


func _show_day_end() -> void:
	var next_day := GameState.day + 1
	eyebrow.text = "HARI %d SELESAI" % GameState.day
	title_label.text = "PERSIAPAN BESOK"
	forecast.visible = true
	shop_column.visible = true
	tomorrow_title.text = GameState.day_event_name(next_day).to_upper()
	tomorrow_description.text = GameState.day_event_description(next_day)
	var schedule: Array = GameState.DAY_SCHEDULE.get(next_day, [])
	roster_label.text = "%d ORANG" % schedule.size()

	var unlock_names := IngredientDB.unlock_names_on_day(next_day)
	unlock.visible = not unlock_names.is_empty()
	unlock_label.text = "%s\nBARU" % unlock_names[0].to_upper() \
		if not unlock_names.is_empty() else ""
	_set_event_art(next_day)
	continue_button.text = "LANJUT KE HARI %d" % next_day

	for i in range(upgrade_box.get_child_count()):
		var button := upgrade_box.get_child(i) as UpgradeCard
		if not button:
			continue
		var id := IDS[i]
		var cost := GameState.upgrade_cost(id)
		button.setup(GameState.upgrade_level(id) + 1, cost, GameState.money >= cost)


func _set_event_art(for_day: int) -> void:
	event_art.texture = EVENT_ICONS.get(for_day, EVENT_ICONS[2])


func _show_run_end(victory: bool) -> void:
	eyebrow.text = "RUN SELESAI"
	title_label.text = "KEDAI DIKENAL PELABUHAN" if victory \
		else "KEDAI KEHILANGAN KEPERCAYAAN"
	served_card.set_value("%d" % GameState.total_served)
	perfect_card.set_value("%d/4" % GameState.discovered_recipes.size())
	forecast.visible = false
	shop_column.visible = false
	continue_button.text = "MAIN LAGI" if victory else "COBA LAGI"


func _animate_entry() -> void:
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.97, 0.97)
	panel.modulate.a = 0.0
	var panel_tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	panel_tween.set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(panel, "scale", Vector2.ONE, 0.28)
	panel_tween.tween_property(panel, "modulate:a", 1.0, 0.22)

	var cards: Array[Control] = []
	for child in stats.get_children():
		cards.append(child as Control)
	if forecast.visible:
		cards.append(forecast)
	for child in upgrade_box.get_children():
		cards.append(child as Control)
	for i in range(cards.size()):
		var card := cards[i]
		card.modulate.a = 0.0
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_interval(0.05 + i * 0.035)
		tween.tween_property(card, "modulate:a", 1.0, 0.18)


func _buy(id: StringName) -> void:
	if GameState.buy_upgrade(id):
		WorldAudioManager.play_ui(WorldAudioManager.PURCHASE, Vector2.ONE, -1.0)
		_refresh()
	else:
		WorldAudioManager.play_ui(WorldAudioManager.LOCK)


func _continue() -> void:
	if GameState.phase in [GameState.Phase.VICTORY, GameState.Phase.GAME_OVER]:
		GameState.start_run()
	else:
		GameState.continue_without_upgrade()
	_go_counter()


func _go_counter() -> void:
	if Rooms.current == Rooms.Room.KASIR:
		get_tree().reload_current_scene()
	else:
		Rooms.go(Rooms.Room.KASIR)
