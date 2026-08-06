class_name DayTransition extends Control

@onready var eyebrow: Label = %Eyebrow
@onready var title_label: Label = %TitleLabel
@onready var summary_label: Label = %SummaryLabel
@onready var money_label: Label = %MoneyLabel
@onready var upgrade_box: VBoxContainer = %UpgradeBox
@onready var continue_button: Button = %ContinueButton

const IDS: Array[StringName] = [
	&"pipisan", &"heat", &"clean", &"patience", &"pay"
]

const LABELS := {
	&"pipisan": "PIPISAN TAJAM  |  +1 potong per hari",
	&"heat": "TUNGKU STABIL  |  fase MATANG lebih panjang",
	&"clean": "LAP KUALI  |  kerak kuali berkurang",
	&"patience": "BANGKU TUNGGU  |  pelanggan lebih sabar",
	&"pay": "PAPAN NAMA  |  bayaran tiap pelanggan naik",
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

	if GameState.phase == GameState.Phase.VICTORY:
		eyebrow.text = "RUN SELESAI"
		title_label.text = "KEDAI ACARAKI DIKENAL PELABUHAN"
		summary_label.text = "Kamu bertahan lima hari dan melayani %d pelanggan.\nResep warisan ditemukan: %d dari 4." % [
			GameState.total_served, GameState.discovered_recipes.size()]
		money_label.text = "Duit akhir: %d  -  Reputasi: %d/10" % [
			GameState.money, GameState.reputation]
		upgrade_box.visible = false
		continue_button.text = "MAIN LAGI"
		return

	if GameState.phase == GameState.Phase.GAME_OVER:
		eyebrow.text = "RUN SELESAI"
		title_label.text = "KEDAI KEHILANGAN KEPERCAYAAN"
		summary_label.text = "Bertahan sampai hari %d dan melayani %d pelanggan." % [
			GameState.day, GameState.total_served]
		money_label.text = "Duit akhir: %d" % GameState.money
		upgrade_box.visible = false
		continue_button.text = "COBA LAGI"
		return

	eyebrow.text = "HARI %d SELESAI" % GameState.day
	title_label.text = "TOKO PERSIAPAN KEDAI"
	var unlock := IngredientDB.next_unlock_text(GameState.day)
	var unlock_line := "\n%s" % unlock if unlock != "" else ""
	summary_label.text = "Terlayani: %d  -  Racikan sempurna: %d  -  Reputasi: %d/10\nBesok - %s: %s\n%s%s" % [
		GameState.day_served, GameState.day_perfect, GameState.reputation,
		GameState.day_event_name(GameState.day + 1),
		GameState.day_event_description(GameState.day + 1),
		GameState.roster_text(GameState.day + 1), unlock_line]
	money_label.text = "Duit %d  -  boleh beli beberapa, atau simpan" % GameState.money
	upgrade_box.visible = true
	continue_button.text = "LANJUT KE HARI %d" % (GameState.day + 1)

	for i in range(upgrade_box.get_child_count()):
		var button := upgrade_box.get_child(i) as Button
		var id := IDS[i]
		var cost := GameState.upgrade_cost(id)
		var next_level := GameState.upgrade_level(id) + 1
		button.text = "%s  |  LV %d  -  %d duit" % [LABELS[id], next_level, cost]
		button.disabled = GameState.money < cost


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
