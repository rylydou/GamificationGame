class_name PlayerSetup extends Control

signal finish

var level_index := 0
var picked_level := ''

@onready var cursor: Control = %Cursor
@onready var turn_label: Label = %TurnLabel
@onready var player_list: Control = %PlayerList
@onready var level_list: Control = %LevelList

var player_menu: Control
var level_button: Control

func _ready() -> void:
	player_menu = player_list.get_child(0)
	player_list.remove_child(player_menu)
	
	level_button = level_list.get_child(0)
	level_list.remove_child(level_button)
	
	for player_data in Game.player_datas:
		add_player_menu(player_data)
	
	for i in LevelDB.level_paths.size():
		var level_name = LevelDB.level_names[i]
		var level_thumbnail = LevelDB.level_thumbnails[i]
		
		var btn := level_button.duplicate()
		btn.find_child('ThumbnailSprite', true, false).texture = level_thumbnail
		btn.find_child('NameLabel', true, false).text = level_name
		level_list.add_child(btn)
	
	var rand_btn := level_button.duplicate()
	rand_btn.find_child('ThumbnailSprite', true, false).texture = preload('res://content/thumbnails/random.png')
	rand_btn.find_child('NameLabel', true, false).text = "Random?"
	level_list.add_child(rand_btn)
	
	update()
	
func open() -> void:
	show()
	picked_level = ''
	for player_data in Game.player_datas:
		player_data.is_ready = false
	for menu in player_list.get_children():
		menu.update()
		menu.no_say()
	update()
	level_list.propagate_call('show')

func update() -> void:
	var color := Consts.player_colors[Game.player_turn_index]
	turn_label.modulate = color
	turn_label.text = "Player %s's turn" % [Game.player_turn_index + 1]
	cursor.modulate = color

func _process(delta: float) -> void:
	if not visible: return
	
	var target_control := level_list.get_child(level_index) as Control
	var target_position := target_control.position
	cursor.size = cursor.size.lerp(target_control.size, .5)
	cursor.position = cursor.position.lerp(target_position + level_list.position, .5)
	
	for input in Game.inputs:
		if not Game.player_datas.any(func(pd: PlayerData): return pd.input.device == input.device):
			if input.is_action_just_pressed('ok'):
				SoundBank.play_ui('ui_join')
				var player_data := PlayerData.new()
				player_data.input = input
				Game.player_datas.append(player_data)
				add_player_menu(player_data)
	
	if Game.player_datas.size() >= 1 and Game.player_datas.all(func(pd): return pd.is_ready) and picked_level.length() > 0:
		finish.emit()
		var level := load(picked_level)
		Globals.main.load_level(level)
		hide()
		return
	
	var picking_player := Game.player_datas[Game.player_turn_index]
	if  picking_player and picking_player.is_ready and picked_level.length() == 0:
		if picking_player.input.is_action_just_pressed('left'):
			SoundBank.play_ui('ui_select')
			level_index -= 1
		if picking_player.input.is_action_just_pressed('right'):
			SoundBank.play_ui('ui_select')
			level_index += 1
		if picking_player.input.is_action_just_pressed('up'):
			SoundBank.play_ui('ui_select')
			level_index -= level_list.columns
		if picking_player.input.is_action_just_pressed('down'):
			SoundBank.play_ui('ui_select')
			level_index += level_list.columns
		level_index = level_index%(LevelDB.level_paths.size() + 1)
		if picking_player.input.is_action_just_pressed('ok'):
			SoundBank.play_ui('ui_pick')
			if level_index == LevelDB.level_paths.size():
				picked_level = LevelDB.level_paths[randi()%LevelDB.level_paths.size()]
			else:
				picked_level = LevelDB.level_paths[level_index]
			for child in level_list.get_children():
				child.hide()
			level_list.get_child(level_index).show()

func add_player_menu(player_data: PlayerData) -> void:
	var menu := player_menu.duplicate()
	menu.player_data = player_data
	player_list.add_child(menu)
