extends Node

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
