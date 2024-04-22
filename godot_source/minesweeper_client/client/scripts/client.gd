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

const ip := "167.71.54.176"
#const ip := "localhost"
const port := "1337"

var window = JavaScriptBridge.get_interface("window")
var peer = WebSocketMultiplayerPeer.new()
var time_elapsed : float = 0
var connected : bool = false

#gotten from server
var player_number: int = -1 
var user_id: int = -1
var lobby_id: int = -1

#gotten from javascript
var username: String = "guest"
var game_mode: int = Modes.default

var mine_coords:= []
var initial_click_location : Vector2i
var mine_number: int = 9
var grid_width: int = 9
var grid_height: int = 9

var over: bool = false

signal win
signal draw
signal lose
signal opponent_tile_uncovered
signal change_text
signal time_update

func send_data_as_JSON(data : Dictionary) -> void:
	peer.put_packet(JSON.stringify(data).to_utf8_buffer())

#gee i wonder

func display_as_background_text(text : String) -> void:
	change_text.emit(text)

#informs the server of win state

func send_win() -> void:

	if over:
		return

	var win_data = {

		"id" : user_id,
		"data_type" : Data.match_data,
		"match_data_type" : Match_Data.win,

	}
	send_data_as_JSON(win_data)


#informs the server of loss state

func send_loss() -> void:

	if over:
		return

	var loss_data = {

		"id" : user_id,
		"data_type" : Data.match_data,
		"match_data_type" : Match_Data.loss,

	}
	send_data_as_JSON(loss_data)


#sends the number of tiles uncovered to the server, to be sent to other client

func send_tile_uncovered(number_uncovered : int) -> void:

	var tile_uncovered_update = {

		"id" : user_id,
		"data_type" : Data.match_data,
		"match_data_type" : Match_Data.tile_uncovered,
		"data" : number_uncovered,

	}
	send_data_as_JSON(tile_uncovered_update)

#sends inputs relevant to the demo to be recorded for the demo file

func send_demo_input(tile_position : Vector2i, input_type : int) -> void:

	var input: = {

		"data_type" : Data.demo,
		"user_id" : user_id,
		"lobby_id" : lobby_id,
		"input" : input_type,
		"x" : tile_position.x,
		"y" : tile_position.y,

	}

	send_data_as_JSON(input)

#just emitters for signals, some of which have a boolean to prevent infinite loops

func pass_draw() -> void:
	over = true
	draw.emit()

func pass_win() -> void:

	over = true
	win.emit()

func pass_lose() -> void:
	over = true
	lose.emit()

#used to update time, so that it is not wildly out of sync with the server due to loading times

func sync_time_with_server(data : Dictionary) -> void:
	time_elapsed = int(data["data"])
	time_update.emit(int(data["data"]))

#handles match specific data, largely by passing it to child elements

func handle_match_data(data : Dictionary):

	var data_type: int = data["match_data_type"]

	match data_type:

		Match_Data.draw:

			pass_draw()

		Match_Data.time:

			sync_time_with_server(data)

		Match_Data.win:

			pass_win()

		Match_Data.loss:

			pass_lose()

		Match_Data.tile_uncovered:

			var tile_number: int = data["data"]
			opponent_tile_uncovered.emit(tile_number)

		_:

			print("match_handler: nothing matched client")

#sends information necessary to join matchmaking

func join_matchmaking() -> void:

	var join_matchmaking_request:= {

		"id" : user_id,
		"data_type" : Data.join_queue,
		"username" : username,
		"game_mode" : game_mode,

	}
	send_data_as_JSON(join_matchmaking_request)

#parses the mine_coordinates string back into an array

func parse_mine_coords_string(string : String) -> void:

	var current_coords_x : String = ""
	var current_coords_y : String = ""
	var looking_at_x : bool = true

	for i in string.length():
		match string[i]:

			"|":

				looking_at_x = false
			
			"&":

				looking_at_x = true
				mine_coords.append(Vector2i(int(current_coords_x), int(current_coords_y)))

				current_coords_x = ""
				current_coords_y = ""

			"i":
				
				initial_click_location = Vector2i(int(current_coords_x), int(current_coords_y))

			_:

				if looking_at_x:
					current_coords_x += str(string[i])
				else:
					current_coords_y += str(string[i])

#maps mode to board dimensions

func get_board_dimensions_from_mode() -> void:

	match game_mode:

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

		Modes.default:

			mine_number = 9
			grid_height = 9
			grid_width = 9

#initialises the game using information from the server, and board dimensions determined by client mode

func initialise_game() -> void:

	display_as_background_text("")
	get_board_dimensions_from_mode()
	var child_board = preload("res://client/scenes/minesweeper_tiled_board.tscn").instantiate()
	add_child(child_board)
	child_board.lose.connect(send_loss)
	child_board.win.connect(send_win)
	child_board.input.connect(send_demo_input)
	child_board.tile_uncovered.connect(send_tile_uncovered)

#changes background text to display time in matchmaking

func display_in_matchmaking(time_in_matchmaking : int) -> void:
	
	var text:= "Matchmaking for " + str(time_in_matchmaking) + " seconds..."
	display_as_background_text(text)


func handle_data(data : Dictionary) -> void:

	var data_type: int = data["data_type"]

	match data_type:

		#confirms the client is properly connected and can join matchmaking

		Data.user_id:
			
			connected = true
			var int_id: int = data["id"]
			user_id = int_id
			join_matchmaking()
			
		#records the client's lobby_id, and confirms that they have joined a lobby so the game can start

		Data.lobby_id:

			var int_id: int = data["id"]
			lobby_id = int_id
			parse_mine_coords_string(data["mine_coords_string"])
			initialise_game()


		Data.wait:

			#just provides the user feedback during what can be a lengthy and uninteractive process
			display_in_matchmaking(data["data"])

		Data.match_data:

			handle_match_data(data)

		_:

			print("data_handler: nothing matched client")

#just polls the client and handles incoming packets

func _process(delta : float) -> void:

	peer.poll()

	if peer.get_available_packet_count() > 0:

		var packet = peer.get_packet()

		if packet != null:

			var data = JSON.parse_string(packet.get_string_from_utf8())

			handle_data(data)

#connects the client to the server

func connect_to_server() -> void:
	var certificate = load("res://client/ssl/minesweeper_self_signed.crt")
	peer.create_client("wss://" + ip + ":" + port, TLSOptions.client_unsafe(certificate))

#grabs relevant variables from the window containing it

func _ready() -> void:

	game_mode = int(window.mode)
	username = window.username

	window.alert("Game loaded, open tab to start game")

	get_board_dimensions_from_mode()
	display_as_background_text("Attemped to connect to server...")
	connect_to_server()

