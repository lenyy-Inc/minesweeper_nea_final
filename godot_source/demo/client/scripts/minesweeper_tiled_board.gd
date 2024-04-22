extends TileMap

var mine_number: int
var grid_height: int 
var grid_width: int 
var board_height: int
var board_width: int
var mine_coords:= []

const beta_tile_id: int = 0
const final_tile_id: int = 1
const tile_size_px: int = 64
const dislay_vertical_offset_from_top: int = 104

#making sprites easier to work with
const spritesheet_space:= Vector2i(0, 0)
const spritesheet_left:= Vector2i(1, 0)
const spritesheet_grid_left:= Vector2i(2, 0)
const spritesheet_top_left:= Vector2i(3, 0)
const spritesheet_grid_top_left:= Vector2i(0, 1)
const spritesheet_grid_space:= Vector2i(3, 3)
const spritesheet_bottom_left:= Vector2i(2, 1)
const spritesheet_bottom:= Vector2i(3, 1)
const spritesheet_bottom_right:= Vector2i(0, 2)
const spritesheet_right:= Vector2i(1, 2)
const spritesheet_grid_right:= Vector2i(2, 2)
const spritesheet_top_right:= Vector2i(3, 2)
const spritesheet_grid_top_right:= Vector2i(0, 3)
const spritesheet_grid_top:= Vector2i(1, 3)
const spritesheet_top:= Vector2i(2, 3)

signal input
signal lose
signal win
signal draw_game
signal tile_uncovered
signal opponent_tile_uncovered
signal time_update
signal initial_click

var player_number
var player_score_position_offset:= Vector2i()
var timer_position_offset:= Vector2i()
var opponent_score_position_offset:= Vector2i()

var track_tiles_uncovered: int = -1
var total_clear_tiles: int = 9223372036854775807 #max integer value
#i dotn know why its set to max integer value but im too scared to chagne it

#creates the background board based on the size of the grid
			
func make_board() -> void:
	
	#set corners
	set_cell(0, Vector2i(0, 0), final_tile_id, spritesheet_top_left)
	set_cell(0, Vector2i(board_width - 1, 0), final_tile_id, spritesheet_top_right)
	set_cell(0, Vector2i(0, board_height - 1), final_tile_id, spritesheet_bottom_left)
	set_cell(0, Vector2i(board_width - 1, board_height - 1), final_tile_id, spritesheet_bottom_right)
	
	#set remaining grid corners
	set_cell(0, Vector2i(0, 2), final_tile_id, spritesheet_grid_top_left)
	set_cell(0, Vector2i(board_width - 1, 2), final_tile_id, spritesheet_grid_top_right)
	
	#set unique edge tiles
	set_cell(0, Vector2i(0, 1), final_tile_id, spritesheet_left)
	set_cell(0, Vector2i(board_width - 1, 1), final_tile_id, spritesheet_right)
	
	#set rows of same tiles
	for i in range(1, board_width - 1):
		
		set_cell(0, Vector2i(i, 0), final_tile_id, spritesheet_top)
		set_cell(0, Vector2i(i, board_height - 1), final_tile_id, spritesheet_bottom)
		set_cell(0, Vector2i(i, 1), final_tile_id, spritesheet_space)
		set_cell(0, Vector2i(i, 2), final_tile_id, spritesheet_grid_top)
	
	#set columns of same tiles
	for i in range(3, board_height - 1):

		set_cell(0, Vector2i(0, i), final_tile_id, spritesheet_grid_left)
		set_cell(0, Vector2i(board_width - 1, i), final_tile_id, spritesheet_grid_right)
		
	for i in range(1, board_width - 1):
		for j in range(3, board_height - 1):

			set_cell(0, Vector2i(i, j), final_tile_id, spritesheet_grid_space)
	
#grabs variables and connects signals to allow cross node communication

func _ready():
	
	player_number = get_parent().player_number
	get_parent().input.connect(pass_inputs)
	
	mine_number = get_parent().mine_number
	grid_width = get_parent().grid_width
	grid_height = get_parent().grid_height
	get_parent().opponent_tile_uncovered.connect(pass_opponent_tile_uncovered)
	get_parent().time_update.connect(pass_time_update)
	get_parent().win.connect(pass_lose)
	get_parent().draw.connect(pass_draw)
	get_parent().lose.connect(pass_win)
	
	total_clear_tiles = (grid_height * grid_width) - mine_number

	board_height= grid_height + 4
	board_width= grid_width + 2

	fit_to_window()

	make_board()
	mine_coords = get_parent().mine_coords

	player_score_position_offset = Vector2i(104, dislay_vertical_offset_from_top)
	timer_position_offset = Vector2i((board_width *  tile_size_px) / 2, dislay_vertical_offset_from_top)
	opponent_score_position_offset = Vector2i(board_width * tile_size_px - 104 , dislay_vertical_offset_from_top)

	var child_grid = preload("res://client/scenes/minesweeper_grid.tscn").instantiate()
	add_child(child_grid) 
	child_grid.lose.connect(pass_lose)
	child_grid.tile_uncovered.connect(pass_tile_uncovered)
	var coordinates : Vector2i = get_parent().initial_click_location
	initial_click.emit(coordinates)

	var child_num_display_player_score = preload("res://client/scenes/num_display_player_score.tscn").instantiate()
	add_child(child_num_display_player_score)

	var child_num_display_opponent_score = preload("res://client/scenes/num_display_opponent_score.tscn").instantiate()
	add_child(child_num_display_opponent_score)

	var child_num_display_timer = preload("res://client/scenes/num_display_timer.tscn").instantiate()
	add_child(child_num_display_timer)
	child_num_display_timer.lose.connect(pass_lose)
	
	#this is to update the tiles uncovered after the initial click
	pass_tile_uncovered()

#these all just fire signals

func pass_inputs(player, coordinate, input_type) -> void:
	if player == player_number:
		input.emit(coordinate, input_type)

func pass_time(time) -> void:
	time_update.emit(time)

func pass_win(sender) -> void:
	if sender == player_number:
		return
	win.emit(player_number)

func pass_tile_uncovered() -> void:

	track_tiles_uncovered += 1

	if track_tiles_uncovered == total_clear_tiles:
		win.emit(player_number)

	tile_uncovered.emit(player_number, track_tiles_uncovered)

func pass_draw(sender) -> void:
	if sender == player_number:
		return
	draw_game.emit(player_number)

func pass_lose(sender) -> void:
	if sender == player_number:
		return
	lose.emit(player_number)

func pass_opponent_tile_uncovered(sender, tile_number) -> void:
	if sender == player_number:
		return
	opponent_tile_uncovered.emit(tile_number)

func pass_time_update(time) -> void:
	time_update.emit(time)

#these both ensure the sizing of the board is correct
	
func fit_to_window() -> void:
	if !((get_window().size.y * board_width) > (get_window().size.x * board_height / 2)):
		scale = Vector2(get_window().size.y / float(board_height * tile_size_px),get_window().size.y / float(board_height * tile_size_px))
	else:
		scale = float(0.5) * Vector2(get_window().size.x / float(board_width * tile_size_px),get_window().size.x / float(board_width * tile_size_px))
	
	var x_offset = (get_window().size.x)/2 - scale.x * board_width * tile_size_px * player_number
	set_position(Vector2i(x_offset, 0))
	
func _process(delta) -> void:
	fit_to_window()

