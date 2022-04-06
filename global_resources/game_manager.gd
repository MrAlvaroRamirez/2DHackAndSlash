extends Node

export(int) var actual_scene
export(String) var scene_name
export(String) var player_path

var path = "res://level_data.json"
var dialog_path = "res://dialogue.json"

var dialoguebox = preload("res://UI/dialogue.tscn")
var dialog_is_active = false setget change_input
var dialog

onready var player = get_node(player_path)

var data
var dialog_data

func _ready():
	decode()
	runMethods()

func decode():
	var file = File.new()
	file.open(path, File.READ)
	data = parse_json(file.get_as_text())
	file.close()
	file.open(dialog_path, File.READ)
	dialog_data = parse_json(file.get_as_text())
	file.close()
	
func runMethods():
	if actual_scene < 0:
		return
	for item in (data.niveles[actual_scene].acts[0].methods):
		call(item.function, item.params)
	
func GiveDialog(dialog_param):
	var dialog_array = dialog_param.split(", ", true)
	find_node(dialog_array[0]).want_to_say = int(dialog_array[1]) + 1

func ShowDialogue(line):
	if dialog_is_active == false:
		dialog = dialoguebox.instance()
		$HUDLayer.add_child(dialog)
		var arr = dialog_data.niveles[actual_scene].dialog[int(line)].lines
		for item in (arr):
			dialog.get_child(0).line_data.append(item.who+";"+item.text+";"+item.state)
			dialog.get_child(0).maxpages = arr.size()
		dialog.get_child(0).set_dialogue_line()
		self.dialog_is_active = true
	
	else:
		dialog.get_child(0).skip()

func change_input(value):
	dialog_is_active = value
	player.hook_trigger = value
	player.disable_input = value
