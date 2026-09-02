class_name DayTransition extends Control

@onready var eyebrow: Label = %Eyebrow
@onready var title_label: Label = %TitleLabel
@onready var served_value: Label = $Panel/Margin/Content/Stats/Served/Box/Value
@onready var perfect_value: Label = $Panel/Margin/Content/Stats/Perfect/Box/Value
@onready var reputation_value: Label = $Panel/Margin/Content/Stats/Reputation/Box/Value
@onready var money_value: Label = $Panel/Margin/Content/Stats/Money/Box/Value
@onready var forecast: Control = %Forecast
@onready var tomorrow_title: Label = %TomorrowTitle
@onready var tomorrow_description: Label = %TomorrowDescription
@onready var roster_label: Label = %RosterLabel
@onready var unlock_label: Label = %UnlockLabel
@onready var shop_title: Label = %ShopTitle
@onready var upgrade_box: GridContainer = %UpgradeBox
@onready var continue_button: Button = %ContinueButton

const IDS: Array[StringName] = [
	&"pipisan", &"heat", &"clean", &"patience", &"pay"
]

const LABELS := {
	&"pipisan": ["PIPISAN TAJAM", "+1 POTONG"],
	&"heat": ["TUNGKU STABIL", "ZONA MATANG +"],
	&"clean": ["LAP KUALI", "AMPAS -"],
	&"patience": ["TEH PENYAMBUT", "SABAR +12%"],
	&"pay": ["PAPAN NAMA", "BAYARAN +8"],
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.phase_changed.connect(_refresh)
	for i in range(upgrade_box.get_child_count()):
		var button := upgrade_box.get_child(i) as Button
		if button:
			button.pressed.connect(_buy.bind(IDS[i]))
	continue_button.pressed.connect(_continue)
	_refresh()


func _refresh() -> void:
	visible = GameState.phase != GameState.Phase.SHIFT
	get_tree().paused = visible
	if not visible:
		return

	served_value.text = "%d" % GameState.day_served
	perfect_value.text = "%d" % GameState.day_perfect
	reputation_value.text = "%d/10" % GameState.reputation
	money_value.text = "%d" % GameState.money

	if GameState.phase == GameState.Phase.VICTORY:
		_show_run_end(true)
		return
	if GameState.phase == GameState.Phase.GAME_OVER:
		_show_run_end(false)
		return

	eyebrow.text = "HARI %d SELESAI" % GameState.day
	title_label.text = "PERSIAPKAN KEDAI UNTUK BESOK"
	forecast.visible = true
	shop_title.visible = true
	upgrade_box.visible = true
	served_value.text = "%d" % GameState.day_served
	perfect_value.text = "%d" % GameState.day_perfect
	tomorrow_title.text = "BESOK · %s" % GameState.day_event_name(GameState.day + 1).to_upper()
	tomorrow_description.text = GameState.day_event_description(GameState.day + 1)
	roster_label.text = GameState.roster_text(GameState.day + 1)
	var unlock := IngredientDB.next_unlock_text(GameState.day)
	unlock_label.visible = unlock != ""
	unlock_label.text = unlock.to_upper()
	continue_button.text = "LANJUT KE HARI %d" % (GameState.day + 1)

	for i in range(upgrade_box.get_child_count()):
		var button := upgrade_box.get_child(i) as Button
		var id := IDS[i]
		var cost := GameState.upgrade_cost(id)
		var next_level := GameState.upgrade_level(id) + 1
		var copy: Array = LABELS[id]
		button.text = "%s\n%s  ·  LV %d  ·  %d DUIT" % [
			copy[0], copy[1], next_level, cost]
		button.disabled = GameState.money < cost


func _show_run_end(victory: bool) -> void:
	eyebrow.text = "RUN SELESAI"
	title_label.text = "KEDAI DIKENAL PELABUHAN" if victory \
		else "KEDAI KEHILANGAN KEPERCAYAAN"
	served_value.text = "%d" % GameState.total_served
	perfect_value.text = "%d/4" % GameState.discovered_recipes.size()
	forecast.visible = false
	shop_title.visible = false
	upgrade_box.visible = false
	continue_button.text = "MAIN LAGI" if victory else "COBA LAGI"


func _buy(id: StringName) -> void:
	if GameState.buy_upgrade(id):
		_refresh()


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
