extends Node

## Autoload: switches between the two rooms of the shop.
##
## Both rooms are separate scenes so each gets a full screen to breathe in —
## the counter can show long complaints and potency bars, the kitchen can
## show the pot, the shelf and the tools without either being cramped.
## GameState keeps the shift running underneath, so this really is just
## walking through a doorway.

enum Room { KASIR, DAPUR }

signal room_changed(room: Room)

const PATHS := {
	Room.KASIR: "res://Scenes/Game/kasir.tscn",
	Room.DAPUR: "res://Scenes/Game/dapur.tscn",
}

const NAMES := {
	Room.KASIR: "KASIR",
	Room.DAPUR: "DAPUR",
}

var current: Room = Room.KASIR
var previous: Room = Room.KASIR

## Counts room changes. Tests use this to assert a switch really happened
## even when the scene name alone would not prove it.
var switch_count: int = 0


## Changing the scene FREES the caller, so any work a room script does
## after calling this runs on a dead node — get_viewport() in particular
## returns null and crashes. Callers must finish their business (including
## set_input_as_handled) BEFORE calling go().
func go(room: Room) -> void:
	if room == current and get_tree().current_scene != null:
		return
	previous = current
	current = room
	switch_count += 1
	get_tree().change_scene_to_file(PATHS[room])
	room_changed.emit(room)


func toggle() -> void:
	go(Room.DAPUR if current == Room.KASIR else Room.KASIR)


func enter_shop() -> void:
	previous = Room.KASIR
	current = Room.KASIR
	get_tree().change_scene_to_file(PATHS[Room.KASIR])
	room_changed.emit(Room.KASIR)


static func display_name(room: Room) -> String:
	return NAMES.get(room, "?")


func other_name() -> String:
	return NAMES[Room.DAPUR] if current == Room.KASIR else NAMES[Room.KASIR]
