extends Node

signal updated_player(id)
signal updated_lobby()

var lobby_info = {}

var player_info = {}

var my_info = {}

func _ready():
	var _error_connected = get_tree().connect("network_peer_connected", self, "_player_connected")
	var _error_disconnected = get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	var _error_server_disconnected = get_tree().connect("server_disconnected", self, "_server_disconnected")

func host_game(_port, _max_players):
	print("Attempting to host on port %s..." % _port)
	
	reset_stuff_lmao_please_help_me()
	
	var peer = NetworkedMultiplayerENet.new()
	var _e = peer.create_server(_port, _max_players)
	
	if _e == OK:
		print("Server hosted on %s." % _port)
		get_tree().network_peer = peer
	else:
		Main.print_error(_e)
	
	return _e

func join_game(_ip, _port):
	print("Attempting to join %s:%s..." % [_ip, _port])
	
	reset_stuff_lmao_please_help_me()
	
	var peer = NetworkedMultiplayerENet.new()
	var _e = peer.create_client(_ip, _port)
	
	if _e == OK:
		print("Joined %s:%s." % [_ip, _port])
		get_tree().network_peer = peer
	else:
		Main.print_error(_e)
	
	return _e
	
func leave_game():
	get_tree().network_peer = null
	Main.change_scene_transition("res://Scenes/States/MultiState.tscn")

func reset_stuff_lmao_please_help_me():
	lobby_info = {}
	player_info = {}

func _player_connected(_id):
	send_player_info(_id)
	
	if get_tree().is_network_server():
		send_lobby_info(_id)
	
func _player_disconnected(_id):
	player_info.erase(_id)

func _server_disconnected():
	leave_game()

func send_player_info(_id=0):
	rpc_id(_id, "update_player_info", my_info)
	emit_signal("updated_player", get_tree().get_network_unique_id())
	
func send_lobby_info(_id=0):
	rpc_id(_id, "update_lobby_info", lobby_info)
	emit_signal("updated_lobby")

remote func update_player_info(_info):
	var _id = get_tree().get_rpc_sender_id()
	player_info[_id] = _info
	
	emit_signal("updated_player", _id)

remote func update_lobby_info(_info):
	lobby_info = _info
	
	emit_signal("updated_lobby")
