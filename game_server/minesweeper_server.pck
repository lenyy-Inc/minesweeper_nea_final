GDPC                �                                                                         T   res://.godot/exported/133200997/export-022ad2090b35cb3d11ab0f98b5ca6beb-server.scn   	      x      ��wQ�`͓�=���        res://.godot/extension_list.cfg �j      /       ��4��=}/A<�U�    ,   res://.godot/global_script_class_cache.cfg  pf             ��Р�8���8~$}P�    D   res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctexPX      �      �̛�*$q�*�́        res://.godot/uid_cache.bin  Pj      I       L��� ��D�bS��E    0   res://addons/godot-sqlite/gdsqlite.gdextension          D      �bJ�c���;��%�y�    ,   res://addons/godot-sqlite/godot-sqlite.gd   P      �      �Y=K��l�������       res://icon.svg  �f      �      C��=U���^Qu��U3       res://icon.svg.import   0e      �       ZkI���;��-5���1       res://project.binary�j      �      3
i���_�	ӒI�'��    (   res://server/scenes/server.tscn.remap    f      c       ��5vE)��]ɖ�3�        res://server/scripts/server.gd  �      �A      ��K]�c>b�%�<�ȋ    ,   res://server/ssl/minesweeper_self_signed.crtPM      F      ����ך�T�~����    ,   res://server/ssl/minesweeper_self_signed.key�Q      �      ��2e�D�L>�'=��        [configuration]

entry_symbol = "sqlite_library_init"
compatibility_minimum = 4.2

[libraries]

macos = "res://addons/godot-sqlite/bin/libgdsqlite.macos.template_debug.framework"
macos.template_release = "res://addons/godot-sqlite/bin/libgdsqlite.macos.template_release.framework"
windows.x86_64 = "res://addons/godot-sqlite/bin/libgdsqlite.windows.template_debug.x86_64.dll"
windows.template_release.x86_64 = "res://addons/godot-sqlite/bin/libgdsqlite.windows.template_release.x86_64.dll"
linux.x86_64 = "res://addons/godot-sqlite/bin/libgdsqlite.linux.template_debug.x86_64.so"
linux.template_release.x86_64 = "res://addons/godot-sqlite/bin/libgdsqlite.linux.template_release.x86_64.so"
android.arm64 = "res://addons/godot-sqlite/bin/libgdsqlite.android.template_debug.arm64.so"
android.template_release.arm64 = "res://addons/godot-sqlite/bin/libgdsqlite.android.template_release.arm64.so"
android.x86_64 = "res://addons/godot-sqlite/bin/libgdsqlite.android.template_debug.x86_64.so"
android.template_release.x86_64 = "res://addons/godot-sqlite/bin/libgdsqlite.android.template_release.x86_64.so"
ios.arm64 = "res://addons/godot-sqlite/bin/libgdsqlite.ios.template_debug.arm64.dylib"
ios.template_release.arm64 = "res://addons/godot-sqlite/bin/libgdsqlite.ios.template_release.arm64.dylib"
web.wasm32 = "res://addons/godot-sqlite/bin/libgdsqlite.web.template_debug.wasm32.wasm"
web.template_release.wasm32 = "res://addons/godot-sqlite/bin/libgdsqlite.web.template_release.wasm32.wasm"

[dependencies]

macos = {}
macos.template_release = {}
windows.x86_64 = {}
windows.template_release.x86_64 = {}
linux.x86_64 = {}
linux.template_release.x86_64 = {}
android.arm64 = {}
android.template_release.arm64 = {}
android.x86_64 = {}
android.template_release.x86_64 = {}
ios.arm64 = {}
ios.template_release.arm64 = {}
web.wasm32 = {}
web.template_release.wasm32 = {}            # ############################################################################ #
# Copyright © 2019-2024 Piet Bronders & Jeroen De Geeter <piet.bronders@gmail.com>
# Licensed under the MIT License.
# See LICENSE in the project root for license information.
# ############################################################################ #

@tool
extends EditorPlugin

func _enter_tree():
	pass

func _exit_tree():
	pass
            RSRC                    PackedScene            ��������                                                  resource_local_to_scene    resource_name 	   _bundled    script       Script    res://server/scripts/server.gd ��������      local://PackedScene_w12rq          PackedScene          	         names "         server    script    Node    	   variants                       node_count             nodes     	   ��������       ����                    conn_count              conns               node_paths              editable_instances              version             RSRC        extends Node

enum Data{

	join_queue,
	user_id,
	wait,
	lobby_id,
	match_data,
	demo,

}

enum Match_Data{

	loss,
	draw,
	win,
	tile_uncovered,
	flag,
	time,

}

enum Modes{

	small,
	medium,
	large,
	default,

}

enum Inputs{

	uncover,
	flag,
	unflag,

}

#must be out here or it would not be kept between calls of _process
var dump_timer : float

const port = 1337

#so god help me if these werent here
var lobbies:= {}
var users:= {}
var matchmaking:= {}
var peer = WebSocketMultiplayerPeer.new()

var database : SQLite

#these arbitrary numbers control the variance and floor of the rank
const elo_const_1: int = 64
const elo_const_2: int = 400
const base_elo : int = 1000 

#much easier to understand things with this function in place rather than the lengthy mess of brackets it contains

func send_data_as_JSON(recipient_id, data) -> void:

	peer.get_peer(recipient_id).put_packet((JSON.stringify(data).to_utf8_buffer()))

#this ended up appearing in a surprising number of functions, so got abstracted out

func send_to_other_in_lobby(sender_id, data) -> void:

	var lobby = lobbies[users[sender_id]["lobby"]]
	var recipient_id

	if lobby["player_1"] == sender_id:
		recipient_id = lobby["player_2"]
	else:
		recipient_id = lobby["player_1"]

	send_data_as_JSON(recipient_id, data)

#this loads the database, and also contains the original sql used to create it, probably better not to lose it

func initialise_database_var() -> void:

	database = SQLite.new()
	database.path = "../db/user_data.db"
	#database.path = "user://database/user_data.db"
	database.open_db()
	database.query("

	CREATE TABLE IF NOT EXISTS users(

	username TEXT NOT NULL,
	password TEXT NOT NULL,
	elo INTEGER NOT NULL,

	PRIMARY KEY(username)

	)
	")

	database.query("

	CREATE TABLE IF NOT EXISTS demos(

	demoID TEXT NOT NULL,
	player1 TEXT NOT NULL,
	player2 TEXT NOT NULL,
	demo TEXT NOT NULL,

	PRIMARY KEY(demoID)
	FOREIGN KEY(player1) REFERENCES users(username)
	FOREIGN KEY(player2) REFERENCES users(username)

	)
	")

#converts the array of mines into a string. probably didnt have to do this but didnt want to get any nasty surprises considering how gdscript is constructed

func mine_array_to_string(mine_coords : Array) -> String:

	var mine_coords_string : String = ""
	
	for coords : Vector2i in mine_coords:
		mine_coords_string += str(coords.x)
		mine_coords_string += "|"
		mine_coords_string += str(coords.y)
		mine_coords_string += "&"
	
	mine_coords_string = mine_coords_string.left(-1)
	mine_coords_string += "i"

	return mine_coords_string

#generates a given number of mines within the given bounds, without creating any duplicates

func place_mines(grid_height : int, grid_width : int, mine_number : int) -> Array:

	var grid:= []
	for i in grid_width:
		grid.append([])
		for j in grid_height:
			grid[i].append(Vector2i(i, j))

	var mine_coords:= []
	var x: int
	var y: int 	

	#the +1 is to generate a random coordinate within the bounds of the board for the initial click to take place
	for i in (mine_number + 1):
		x = randi_range(0, grid_width - 1)
		y = randi_range(0, grid_height - 1)
		
		while mine_coords.has(grid[x][y]):
			x = randi_range(0, grid_width - 1)
			y = randi_range(0, grid_height - 1)

		mine_coords.append(Vector2i(x, y))
	
	return mine_coords


func generate_random_id() -> int:

	var rng = RandomNumberGenerator.new()

	var id_string = ""
	for i in range(0, 15):
		id_string  += str(rng.randi_range(0, 9))

	var id: int = int(id_string)

	return id

#handles all the necessary dictionary creation and key assignment to create a lobby, as well as giving that lobby mine coordinates

func create_new_lobby(player_1_id : int, player_2_id : int) -> void:

	var new_lobby_id: int = generate_random_id()
	var player_1 = users[player_1_id]
	var player_2 = users[player_2_id]

	var grid_height : int
	var grid_width : int
	var mine_number : int

	match int(player_1["game_mode"]):

		Modes.small:

			mine_number = 10
			grid_height = 10
			grid_width = 10

		Modes.medium:

			mine_number = 40
			grid_height = 16
			grid_width = 16

		Modes.large:

			mine_number = 99
			grid_height = 16
			grid_width = 30

		_:

			mine_number = 9
			grid_height = 9
			grid_width = 9

	var mine_placements:= place_mines(grid_height,grid_width,mine_number)
	var mine_placements_string:= mine_array_to_string(mine_placements)

	lobbies[new_lobby_id] = {

		"id" : new_lobby_id,
		"player_1" : player_1["id"],
		"player_2" : player_2["id"],
		"mine_coords" : mine_placements,
		"time_elapsed" : 0,
		"demo" : {

			"mine_coords" : mine_placements,
			"mine_number" : mine_number,
			"grid_width" : grid_width,
			"grid_height" : grid_height,

		},

	}
	

	player_1["lobby"] = new_lobby_id 
	player_2["lobby"] = new_lobby_id 

	var send_lobby = {

		"data_type" : Data.lobby_id,
		"id" : new_lobby_id,
		"mine_coords_string" : mine_placements_string,

	}

	send_data_as_JSON(player_1["id"], send_lobby)
	send_data_as_JSON(player_2["id"], send_lobby)

	matchmaking.erase(player_1_id)
	matchmaking.erase(player_2_id)


func is_better_match(candidate_1, candidate_2, elo_difference) -> bool:

	if not candidate_1["current_elo_gap"] == null:
		if candidate_1["current_elo_gap"] <= elo_difference:
			return false

	if not candidate_2["current_elo_gap"] == null:
		if candidate_2["current_elo_gap"] <= elo_difference:
			return false

	return true

#this is just an algorithm that delivers the ideal matchmade pair (if one is possible) each time it is run, which is every frame there are multiple users connected to the server

func matchmake() -> void:

	var in_matchmaking:= []
	var match_conditions: bool 
	var difference_lenience: int
	var elo_difference: int

	in_matchmaking = matchmaking.keys()

	for i in range(0, in_matchmaking.size() - 1):
		for j in range(i + 1, in_matchmaking.size()):


			var candidate_1 = matchmaking[in_matchmaking[i]]

			var candidate_2 = matchmaking[in_matchmaking[j]]

			if candidate_1["username"] == candidate_2["username"]:
				if!(candidate_1["username"] == "guest"):
					continue

			elo_difference = candidate_1["elo"] - candidate_2["elo"]
			if elo_difference < 0:
				elo_difference = elo_difference * -1
			difference_lenience = 5 * (candidate_1["time_waited"] + 1) * (candidate_2["time_waited"] + 1)
			if difference_lenience > 100:
				difference_lenience = 100
			match_conditions = elo_difference <= difference_lenience

			if (match_conditions and is_better_match(candidate_1, candidate_2, elo_difference)) and (candidate_1["game_mode"] == candidate_2["game_mode"]):
				
				candidate_1["current_opponent"] = candidate_2["id"]
				candidate_2["current_opponent"] = candidate_1["id"]
				candidate_1["current_elo_gap"] = elo_difference
				candidate_2["current_elo_gap"] = elo_difference
		
	for key in in_matchmaking:

		if not matchmaking.has(key):
			continue

		var user = matchmaking[key]

		if (user["current_opponent"] == null):
			continue

		if not matchmaking.has(user["current_opponent"]):
			user["current_opponent"] = null
			continue

		var user_chosen_opponent = matchmaking[user["current_opponent"]]

		if user["id"] == user_chosen_opponent["current_opponent"]:

			create_new_lobby(user["id"], user_chosen_opponent["id"])


func new_elo_calc(initial_elo : float, other_elo : float, outcome : float) -> int:

	var new_elo = initial_elo + elo_const_1 * ((outcome / 2) - (pow(10, (initial_elo / elo_const_2)) / (pow(10, (initial_elo / elo_const_2)) + pow(10, (other_elo / elo_const_2)))))
	if new_elo < base_elo:
		new_elo = base_elo
	
	return new_elo

#just does some maths to update elos after a match depending on outcome
#the Match enum is structured to that dividing the outcome by 2 maps to the float value needed for the elo calculation

func update_elos(lobby : Dictionary, outcome_for_p1 : int) -> void:

	var outcome_for_p2 = outcome_for_p1 + 2 - (2 * outcome_for_p1)

	var elo_1 = int((database.select_rows("users", "username = " + "'" + users[lobby["player_1"]]["username"] + "'", ["elo"]))[0]["elo"])
	var elo_2 = int((database.select_rows("users", "username = " + "'" + users[lobby["player_2"]]["username"] + "'", ["elo"]))[0]["elo"])

	var new_elo_1 = new_elo_calc(elo_1, elo_2, outcome_for_p1)
	var new_elo_2 = new_elo_calc(elo_2, elo_1, outcome_for_p2)

	database.update_rows("users", "username = "  + "'" + str(users[lobby["player_1"]]["username"]) + "'", {

		"elo" : new_elo_1,

	}
	)

	database.update_rows("users", "username = "  + "'" + str(users[lobby["player_2"]]["username"]) + "'", {


		"elo" : new_elo_2,

	}
	)

#inserts demo into database

func put_demo_in_database(lobby : Dictionary) -> void:

	lobbies.erase(lobby["id"])

	database.insert_row("demos", {

		"demoID" : lobby["id"],
		"player1" : users[lobby["player_1"]]["username"],
		"player2" : users[lobby["player_2"]]["username"],
		"demo" : JSON.stringify(lobby["demo"]),

	})
	
	await get_tree().create_timer(1.0).timeout

	if users.has(lobby["player_1"]):
		peer.disconnect_peer(lobby["player_1"])
	if users.has(lobby["player_2"]):
		peer.disconnect_peer(lobby["player_2"])

func handle_win_or_loss(sender_id : int, outcome : int) -> void:
	
	var message:= {}
	var lobby = lobbies[users[sender_id]["lobby"]]

	if outcome == Match_Data.loss:
		
		message = {

		"data_type" : Data.match_data,
		"match_data_type" : Match_Data.win,

		}

		send_to_other_in_lobby(sender_id, message)

	elif outcome == Match_Data.win:

		message = {

		"data_type" : Data.match_data,
		"match_data_type" : Match_Data.loss,

		}

		send_to_other_in_lobby(sender_id, message)

	else:

		message = {

		"data_type" : Data.match_data,
		"match_data_type" : Match_Data.draw,

		}

		send_data_as_JSON(lobby["player_1"], message)
		send_data_as_JSON(lobby["player_2"], message)

	put_demo_in_database(lobby)

	if outcome == Match_Data.draw:
		update_elos(lobby, Match_Data.draw)
		return

	if lobby["player_1"] == sender_id:
		update_elos(lobby, outcome)
		return

	if lobby["player_2"] == sender_id:
		update_elos(lobby, (outcome + 2 - (2 * outcome)))
		return


#tells player to update the score of their opponent

func send_updated_tile_uncovered(sender_id : int, tile_number : int) -> void:

	var update_opponent_tile_number:= {

		"data_type" : Data.match_data,
		"match_data_type" : Match_Data.tile_uncovered,
		"data" : tile_number,

	}

	send_to_other_in_lobby(sender_id, update_opponent_tile_number)

#specifically handles data pertaining to active matches, separated from other data handler for readability

func handle_match_data(data : Dictionary) -> void:

	var data_type: int = data["match_data_type"]

	match data_type:

		Match_Data.win:

			var int_id = int(data["id"])
			handle_win_or_loss(int_id, Match_Data.win)

		Match_Data.loss:

			var int_id = int(data["id"])

			handle_win_or_loss(int_id, Match_Data.loss)

		Match_Data.tile_uncovered:

			var int_id: int = data["id"]
			var tile_number: int = data["data"]
			send_updated_tile_uncovered(int_id, tile_number)

		_:

			print("match_handler: nothing matched server")

#puts extra user data in the users dictionary, and adds them to matchmaking

func add_player_to_queue(data : Dictionary) -> void:

	var int_id: int = data["id"]
	print((database.select_rows("users", "username = " + "'" + data["username"] + "'", ["elo"]))[0]["elo"])
	var int_elo: int = (database.select_rows("users", "username = " + "'" + data["username"] + "'", ["elo"]))[0]["elo"]

	print("placed into matchmaking")
	matchmaking[int_id] = {

	"id" : int_id,
	"elo" : int_elo,
	"current_opponent" : null,
	"current_elo_gap" : null,
	"time_waited" : 0,
	"game_mode" : data["game_mode"],
	"username" : data["username"],

	}

	var extra_user_data = {

	"username" : data["username"],
	"elo" : int_elo,
	"game_mode" : data["game_mode"],

	}

	print(users[int_id])

	users[int_id].merge(extra_user_data)

#adds inputs to the demos dictionary so that it can be used as parseable JSON by the demo player

func write_demo(data : Dictionary) -> void:
	
	var lobby = lobbies[int(data["lobby_id"])]
	var input_type : int = data["input"]
	var is_player_1: bool = int(data["user_id"]) == int(lobby["player_1"])

	if is_player_1:
		lobby["demo"][str(lobby["time_elapsed"])] = {

			"player" : "player_1",
			"input" : input_type,
			"x" : int(data["x"]),
			"y" : int(data["y"]),

		}
		return
	
	lobby["demo"][str(lobby["time_elapsed"])] = {

		"player" : "player_2",
		"input" : input_type,
		"x" : int(data["x"]),
		"y" : int(data["y"]),

	}



#just does as it says

func handle_data(data : Dictionary) -> void:

	var data_type: int = data["data_type"]

	match data_type:

		Data.demo:

			#handles inputs to be recorded in the demo JSON
			write_demo(data)

		Data.join_queue:

			#puts a player in matchmaking after they send over relevant info
			add_player_to_queue(data)

		Data.match_data:

			#goes to another function to handle data specific to ongoing matches for readability and to avoid cluttered enums
			handle_match_data(data)

		_:

			print("nothing matched server")


func _process(delta : float) -> void:

	#just polls the server
	peer.poll()

	#increments timer that is used to dump data periodically
	dump_timer += delta
	if dump_timer > 10:
		dump_info_to_console()
		dump_timer = 0

	#handles incoming packets
	if peer.get_available_packet_count() > 0:

		var packet = peer.get_packet()

		if packet != null:

			var data = JSON.parse_string(packet.get_string_from_utf8())
			handle_data(data)
	
	#starts matchmaking if necessary
	if matchmaking.size() >= 2:
		matchmake()
		
	#tells users how long they have been in queue
	var ids:= matchmaking.keys()
	for id in ids:
		
		matchmaking[id]["time_waited"] += delta

		if int(matchmaking[id]["time_waited"]) > int(matchmaking[id]["time_waited"] - delta):

			var wait_message = {

			"data_type" : Data.wait,
			"data" : int(matchmaking[id]["time_waited"]),

			}
	
			send_data_as_JSON(id, wait_message)

	#increments the time in all lobbies (this ensures the time is synced and that the server is the arbiter of what happens when in demos as the time is tracked by the server)
	var lobby_ids:= lobbies.keys()
	for lobby_id in lobby_ids:
	
		var lobby = lobbies[lobby_id]

		if lobby["time_elapsed"] >= 0:
			lobby["time_elapsed"] += delta

		if int(lobby["time_elapsed"]) > int(lobby["time_elapsed"] - delta):

			print(int(lobby["time_elapsed"]))

			var time:= {

				"data_type" : Data.match_data,
				"match_data_type" : Match_Data.time,
				"data" : int(lobby["time_elapsed"])

			}

			send_data_as_JSON(lobby["player_1"], time)
			send_data_as_JSON(lobby["player_2"], time)

		if lobby["time_elapsed"] >= 999:
			lobby["time_elapsed"] = -1
			handle_win_or_loss(lobby["player_1"], Match_Data.draw)

#uses key and certificate to host server on secure websocket

func start_server() -> void:
	var key = load("res://server/ssl/minesweeper_self_signed.key")
	var certificate = load("res://server/ssl/minesweeper_self_signed.crt")
	peer.create_server(port, "*", TLSOptions.server(key, certificate))
	print("server started")

#on disconnect clears the user from all dictionaries and ends the lobby, giving the user that didnt disconnect early a win

func peer_disconnected(id : int) -> void:

	if users[id].has("lobby") and lobbies.has(users[id]["lobby"]):

		handle_win_or_loss(id, Match_Data.loss)

	if matchmaking.has(id):
		matchmaking.erase(id)
		
	users.erase(id)

#on connect infomrs user of their id as given by the server, and adds their id to the users dictionary

func peer_connected(id : int) -> void:
	print("user " + str(id) + " connected")
	var send_id = {

		"data_type" : Data.user_id,
		"id" : id,

	}
	send_data_as_JSON(id, send_id)
	users[id] = {

		"id" : id,

	}

#fires on start, connects necessary signals and to database

func _ready() -> void:

	initialise_database_var()
	peer.peer_connected.connect(peer_connected)
	peer.peer_disconnected.connect(peer_disconnected)
	start_server()

#allows the dictionaries of the server to be viewed periodically

func dump_info_to_console() -> void:

	print("dumping users")
	print("-------")

	var user_ids:= users.keys()
	for user_id in user_ids:

		print("-------")
		var user = users[user_id]
		var user_keys = user.keys()
		for key in user_keys:
			print(str(key) + " : " + str(user[key]))

	print("-------")
		
	print("dumping matchmaking")
	print("-------")

	var ids:= matchmaking.keys()
	for id in ids:

		print("-------")
		var matchmaking_user = matchmaking[id]
		var matchmaking_user_keys = matchmaking_user.keys()
		for key in matchmaking_user_keys:
			print(str(key) + " : " + str(matchmaking_user[key]))

	print("-------")

	print("dumping lobbies")
	print("-------")

	var lobby_ids:= lobbies.keys()
	for lobby_id in lobby_ids:

		print("-------")
		var lobby = lobbies[lobby_id]
		var lobby_keys = lobby.keys()
		for key in lobby_keys:
			print(str(key) + " : " + str(lobby[key]))

	print("-------")
            -----BEGIN CERTIFICATE-----
MIIC+zCCAeOgAwIBAgIUCTRwjmbqkhD/HZC0t5uR+jkjSkkwDQYJKoZIhvcNAQEL
BQAwDTELMAkGA1UEBhMCVUswHhcNMjQwNDE3MDgyOTQxWhcNMjUwNDE3MDgyOTQx
WjANMQswCQYDVQQGEwJVSzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AJZ4OkZCVqiqrds1LTNnQ3RYNu62BOlIxrlP+b4AQhlBEECFWxyYCcL0fJMV8uL6
ODQPsZ5FGhcJ/ay3S6/TPnr1/JP/Ja8K4G1UU9h613P5tHfSIhMc9V4fqofm4nsY
qC/cvipGRc0FYTjo3jCMKxT/T/DwjDSwscqYqWH+xgmfetDqleLsrXxfWCI/H/jM
nsfFEOXt0+nfRUuciyVIkgYiIY7FDKkKMBCJn6VttEvrZNMjZ7ca7vrxGy9YZIc6
tjffkLYd4wYgoFCbBiwnNWvZbi9HOlx/7qhmGqJ1TbjxrgihXTD6pId9GUvcWT1M
0SdLI+WLYvInDFcdhYNX308CAwEAAaNTMFEwHQYDVR0OBBYEFIb9gVmJ09hEAULr
dMQJdJlq0buOMB8GA1UdIwQYMBaAFIb9gVmJ09hEAULrdMQJdJlq0buOMA8GA1Ud
EwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAG9vBECoEyZF4GB36X2jy7ps
sfGgtRkAANi/pt9xADhJCaRE0hUhLg/OBcTgGNfPK7Zp04JgQzMiJvkGDGXfnO3C
StKJ+1eDHPyWOSEu2HQ6qXqdV8xPwpL8yW+sQn2gn1cTG5xuj+6XF30ATHeM75Uc
lfQ5FAxu8zABfsU1bwOSg5+csBJVU0M1gCAPFaJ1WWgIBNhhyfk8kXxVwFpvoIZs
wsaGXiCtg+J89CH+L+DU/8baTBYeVsW9lbhFmIh6TWrpuMeRUzsxHFqQPbmw9cog
kFJ3qKOszpRrxcvoLFkQ5JmBKP4XaMDjcxtWRfij3F2TIhW6CTuj4JzYLTLXtTY=
-----END CERTIFICATE-----
          -----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCWeDpGQlaoqq3b
NS0zZ0N0WDbutgTpSMa5T/m+AEIZQRBAhVscmAnC9HyTFfLi+jg0D7GeRRoXCf2s
t0uv0z569fyT/yWvCuBtVFPYetdz+bR30iITHPVeH6qH5uJ7GKgv3L4qRkXNBWE4
6N4wjCsU/0/w8Iw0sLHKmKlh/sYJn3rQ6pXi7K18X1giPx/4zJ7HxRDl7dPp30VL
nIslSJIGIiGOxQypCjAQiZ+lbbRL62TTI2e3Gu768RsvWGSHOrY335C2HeMGIKBQ
mwYsJzVr2W4vRzpcf+6oZhqidU248a4IoV0w+qSHfRlL3Fk9TNEnSyPli2LyJwxX
HYWDV99PAgMBAAECggEAI7AwYimp1CdnRO6/4clEPnwNy2BwmcQhHiLR4Ta+dq7v
4929VnLZHdxPD7PM//jJC9ANGLTbE0vTVvvCf9lioFdnqNKDZZj20feGS3oXT/KR
0zmLy2y65bAtCj7AyOF4QqHgmLZCJ/Z2sMDKskkMjtZfZ44mMvkVsi+zPQLoha9o
djozcqN1/iH2/EK95dPX0GygXXEUw0lEgB8sv1TgN+pb9Kx2x9WPpKFw9xcqx0cR
U7BNwQ2bvSLNRhPofOaX0LBbPmPIuSC27aRYH9NYPt/wLBqueliRTpsxe8azfep2
TRwM/KVVujevESYqii6hHL3Pp4YyI8HS+7VTZaKggQKBgQDQNRQYBkGz7pqOsmEs
/dA/pU57MOXVSWBfGZzTI+0q4Rv6pFEF2erN37Raho0VRyx3jvTpmkXTQPULXqv/
LSzJZKvK2AWpRY/EE8S1bhM7u/LL6R42iYud5KECca/OjgTphgLpxjFsqehzL3yZ
NXlTjE3WsUB4GU2ZMnQiw0lBtwKBgQC5Akyl97IURhg8OY4zqaoQRlv1EFBKtZvj
iY4yj+OlH1Ds0+qMmfQtMGuCpDYZcc79sLiMUd/VUvnp/Kj+cBKXMjHdE7wkuOaA
CUReHOJvLRCt7wXs8pdeN6PkCFHT8R488P2s2dE3WIz8ZYsrJEQWQQS9PWtNPGQT
qVV499JvKQKBgQCO/oVIYrOpMgwwSM54qfDmZU/bR5/xti1b4ylT0W7HbkdbApMq
45lhv2wMaDBpFrKxghsufOfLyOcC4ghaftotjth1vZtVwBKW5cTJnknTUqfT58z6
Q8kBrc3u8cl+oQc6ovFJQPcc3CxrP4fhaVpkSQ4Ej0Ppt+cVehNM9LZRTQKBgHjP
05WdhiBPFYxeWUnLRU6TY4FIQeZHaaDQNpc19wXgyUudptBhyF2p/Mq2yM0c0HpB
aIHZBT2cja4KW6CrNridAorHVFj2lS6O3qJGYmcPGpE6QLhWQho4Y0GJXUX1cjWB
eWXiZwipPoejF5n4eK2/j4S0EtnA0ek07qerzTLhAoGAfsHtNaBlkBRb+P6xT1Sl
VlTuE7Ddr40mL1imLNpA9sdTTPo8rqRtaRW7rdMfhhBKK8iG1jjBmP4pGxiRU5nA
/pUFVT7juuHoDBS8DUNj1hC3RJ81kMgOLaxvHQQgjjkViH594irOBJnf5kSIsPyR
WNuJFDMRApUDAGwZq/p1j3c=
-----END PRIVATE KEY-----
        GST2   �   �      ����               � �        �  RIFF�  WEBPVP8L�  /������!"2�H�$�n윦���z�x����դ�<����q����F��Z��?&,
ScI_L �;����In#Y��0�p~��Z��m[��N����R,��#"� )���d��mG�������ڶ�$�ʹ���۶�=���mϬm۶mc�9��z��T��7�m+�}�����v��ح�m�m������$$P�����එ#���=�]��SnA�VhE��*JG�
&����^x��&�+���2ε�L2�@��		��S�2A�/E���d"?���Dh�+Z�@:�Gk�FbWd�\�C�Ӷg�g�k��Vo��<c{��4�;M�,5��ٜ2�Ζ�yO�S����qZ0��s���r?I��ѷE{�4�Ζ�i� xK�U��F�Z�y�SL�)���旵�V[�-�1Z�-�1���z�Q�>�tH�0��:[RGň6�=KVv�X�6�L;�N\���J���/0u���_��U��]���ǫ)�9��������!�&�?W�VfY�2���༏��2kSi����1!��z+�F�j=�R�O�{�
ۇ�P-�������\����y;�[ ���lm�F2K�ޱ|��S��d)é�r�BTZ)e�� ��֩A�2�����X�X'�e1߬���p��-�-f�E�ˊU	^�����T�ZT�m�*a|	׫�:V���G�r+�/�T��@U�N׼�h�+	*�*sN1e�,e���nbJL<����"g=O��AL�WO!��߈Q���,ɉ'���lzJ���Q����t��9�F���A��g�B-����G�f|��x��5�'+��O��y��������F��2�����R�q�):VtI���/ʎ�UfěĲr'�g�g����5�t�ۛ�F���S�j1p�)�JD̻�ZR���Pq�r/jt�/sO�C�u����i�y�K�(Q��7őA�2���R�ͥ+lgzJ~��,eA��.���k�eQ�,l'Ɨ�2�,eaS��S�ԟe)��x��ood�d)����h��ZZ��`z�պ��;�Cr�rpi&��՜�Pf��+���:w��b�DUeZ��ڡ��iA>IN>���܋�b�O<�A���)�R�4��8+��k�Jpey��.���7ryc�!��M�a���v_��/�����'��t5`=��~	`�����p\�u����*>:|ٻ@�G�����wƝ�����K5�NZal������LH�]I'�^���+@q(�q2q+�g�}�o�����S߈:�R�݉C������?�1�.��
�ڈL�Fb%ħA ����Q���2�͍J]_�� A��Fb�����ݏ�4o��'2��F�  ڹ���W�L |����YK5�-�E�n�K�|�ɭvD=��p!V3gS��`�p|r�l	F�4�1{�V'&����|pj� ߫'ş�pdT�7`&�
�1g�����@D�˅ �x?)~83+	p �3W�w��j"�� '�J��CM�+ �Ĝ��"���4� ����nΟ	�0C���q'�&5.��z@�S1l5Z��]�~L�L"�"�VS��8w.����H�B|���K(�}
r%Vk$f�����8�ڹ���R�dϝx/@�_�k'�8���E���r��D���K�z3�^���Vw��ZEl%~�Vc���R� �Xk[�3��B��Ğ�Y��A`_��fa��D{������ @ ��dg�������Mƚ�R�`���s����>x=�����	`��s���H���/ū�R�U�g�r���/����n�;�SSup`�S��6��u���⟦;Z�AN3�|�oh�9f�Pg�����^��g�t����x��)Oq�Q�My55jF����t9����,�z�Z�����2��#�)���"�u���}'�*�>�����ǯ[����82һ�n���0�<v�ݑa}.+n��'����W:4TY�����P�ר���Cȫۿ�Ϗ��?����Ӣ�K�|y�@suyo�<�����{��x}~�����~�AN]�q�9ޝ�GG�����[�L}~�`�f%4�R!1�no���������v!�G����Qw��m���"F!9�vٿü�|j�����*��{Ew[Á��������u.+�<���awͮ�ӓ�Q �:�Vd�5*��p�ioaE��,�LjP��	a�/�˰!{g:���3`=`]�2��y`�"��N�N�p���� ��3�Z��䏔��9"�ʞ l�zP�G�ߙj��V�>���n�/��׷�G��[���\��T��Ͷh���ag?1��O��6{s{����!�1�Y�����91Qry��=����y=�ٮh;�����[�tDV5�chȃ��v�G ��T/'XX���~Q�7��+[�e��Ti@j��)��9��J�hJV�#�jk�A�1�^6���=<ԧg�B�*o�߯.��/�>W[M���I�o?V���s��|yu�xt��]�].��Yyx�w���`��C���pH��tu�w�J��#Ef�Y݆v�f5�e��8��=�٢�e��W��M9J�u�}]釧7k���:�o�����Ç����ս�r3W���7k���e�������ϛk��Ϳ�_��lu�۹�g�w��~�ߗ�/��ݩ�-�->�I�͒���A�	���ߥζ,�}�3�UbY?�Ӓ�7q�Db����>~8�]
� ^n׹�[�o���Z-�ǫ�N;U���E4=eȢ�vk��Z�Y�j���k�j1�/eȢK��J�9|�,UX65]W����lQ-�"`�C�.~8ek�{Xy���d��<��Gf�ō�E�Ӗ�T� �g��Y�*��.͊e��"�]�d������h��ڠ����c�qV�ǷN��6�z���kD�6�L;�N\���Y�����
�O�ʨ1*]a�SN�=	fH�JN�9%'�S<C:��:`�s��~��jKEU�#i����$�K�TQD���G0H�=�� �d�-Q�H�4�5��L�r?����}��B+��,Q�yO�H�jD�4d�����0*�]�	~�ӎ�.�"����%
��d$"5zxA:�U��H���H%jس{���kW��)�	8J��v�}�rK�F�@�t)FXu����G'.X�8�KH;���[             [remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://cdysajvg3tjb8"
path="res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex"
metadata={
"vram_texture": false
}
                [remap]

path="res://.godot/exported/133200997/export-022ad2090b35cb3d11ab0f98b5ca6beb-server.scn"
             list=Array[Dictionary]([])
     <svg height="128" width="128" xmlns="http://www.w3.org/2000/svg"><rect x="2" y="2" width="124" height="124" rx="14" fill="#363d52" stroke="#212532" stroke-width="4"/><g transform="scale(.101) translate(122 122)"><g fill="#fff"><path d="M105 673v33q407 354 814 0v-33z"/><path fill="#478cbf" d="m105 673 152 14q12 1 15 14l4 67 132 10 8-61q2-11 15-15h162q13 4 15 15l8 61 132-10 4-67q3-13 15-14l152-14V427q30-39 56-81-35-59-83-108-43 20-82 47-40-37-88-64 7-51 8-102-59-28-123-42-26 43-46 89-49-7-98 0-20-46-46-89-64 14-123 42 1 51 8 102-48 27-88 64-39-27-82-47-48 49-83 108 26 42 56 81zm0 33v39c0 276 813 276 813 0v-39l-134 12-5 69q-2 10-14 13l-162 11q-12 0-16-11l-10-65H447l-10 65q-4 11-16 11l-162-11q-12-3-14-13l-5-69z"/><path d="M483 600c3 34 55 34 58 0v-86c-3-34-55-34-58 0z"/><circle cx="725" cy="526" r="90"/><circle cx="299" cy="526" r="90"/></g><g fill="#414042"><circle cx="307" cy="532" r="60"/><circle cx="717" cy="532" r="60"/></g></g></svg>
             ���S   res://server/scenes/server.tscn?�0؁��E   res://icon.svg       res://addons/godot-sqlite/gdsqlite.gdextension
 ECFG      application/config/name         minesweeper_server     application/run/main_scene(         res://server/scenes/server.tscn    application/config/features(   "         4.2    GL Compatibility       application/config/icon         res://icon.svg  #   rendering/renderer/rendering_method         gl_compatibility*   rendering/renderer/rendering_method.mobile         gl_compatibility    