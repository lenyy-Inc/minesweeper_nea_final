extends TileMap

enum Inputs{

	uncover,
	flag,
	unflag,

}

const default_grid_constant: float = 10 
const beta_tile_id: int = 0
const alpha_tile_id: int = 1
const final_tile_id: int = 2

var mine_number: int 
var grid_width: int 
var grid_height: int 

const mine_layer_index: int = 1
const numbers_layer_index: int = 2
const cover_layer_index: int = 3
const flag_layer_index: int = 4

const spritesheet_mine:= Vector2i(0, 0)
const spritesheet_flag:= Vector2i(0, 1)
const spritesheet_cover:= Vector2i(5, 0)
const spritesheet_clear_tile:= Vector2i(5, 1)

var grid:= []

signal lose
signal tile_uncovered
signal input

#does what it says

func initialise_variables() -> void:
	
	set_position(Vector2(64, 192))
	
	mine_number = get_parent().mine_number
	grid_width = get_parent().grid_width
	grid_height = get_parent().grid_height

#does what it says
	
func place_mines() -> void:
	
	var mine_coords:= []
	mine_coords = get_parent().mine_coords

	for i in mine_coords:
		
		set_cell(mine_layer_index, i, final_tile_id, spritesheet_mine)

#does what it says

func create_grid_layout() -> void:
	
	place_mines()
	set_number_cells()
	
#uses a weird function to get all 8 coordinates aground a point (and the point itself)

func get_all_adjacent(coords : Vector2i) -> Array:
	
	var x: int
	var y: int

	var array_of_adjacent_tiles:= []
	var repeated_operation = func(i : float) -> int: return round(i/3)
	var within_grid: bool
	
	for i in range(-4,5):
		
		#these just map the values from -4 to 4 to the coordinates around a given point
		x = coords.x + (i - (3 * repeated_operation.call(i)))
		y = coords.y + repeated_operation.call(i)
		
		#pulled this out because it was confusing, only necessary due to lack of try statement in godot
		within_grid = ((-1 < x) and (x < grid_width)) and ((-1 < y) and (y < grid_height))
		
		if within_grid and (grid[x][y] != coords):
			array_of_adjacent_tiles.append(Vector2i(x,y))
			
	return array_of_adjacent_tiles

#based on mine coordinates, gives squares the number of adjacent mines as a texture

func set_number_cells():
	
	var number_of_surrounding_mines: int
	var currently_looked_at_cell: Vector2i
	var mine_num_to_tile: Vector2i
	
	for i in grid_width:
		for j in grid_height:
			
			mine_num_to_tile = Vector2i(5, 1)
			currently_looked_at_cell = grid[i][j]
			number_of_surrounding_mines = 0
			
			if !(has_tile_type(currently_looked_at_cell, mine_layer_index, spritesheet_mine)):
				
				for k in get_all_adjacent(currently_looked_at_cell):

					if has_tile_type(k, mine_layer_index, spritesheet_mine):
						number_of_surrounding_mines += 1
					
				if number_of_surrounding_mines !=0:

					#maps to the coordinate, taking advatage of automatic truncation when dividing integers 
					mine_num_to_tile = Vector2i( ( number_of_surrounding_mines - (number_of_surrounding_mines/5) * 4), ((number_of_surrounding_mines)/5))
				
				set_cell(numbers_layer_index, currently_looked_at_cell, final_tile_id, mine_num_to_tile)

#covers the board 

func make_cover() -> void:

	for i in grid_width:
		for j in grid_height:
			set_cell(cover_layer_index, Vector2i(i, j), final_tile_id, spritesheet_cover)

#checks if a coordinate has a certain tile type on a certain layer

func has_tile_type(VectorPos: Vector2i, tile_layer: int, tile_sprite_atlas_coords: Vector2i) -> bool:
	
	return get_cell_atlas_coords(tile_layer, VectorPos) == tile_sprite_atlas_coords

#creates the grid and the visuals for it

func _ready():
	
	get_parent().draw_game.connect(end_game)
	get_parent().win.connect(end_game)
	get_parent().lose.connect(end_game)
	
	get_parent().initial_click.connect(initial_click)

	initialise_variables()
	
	for i in grid_width:
		grid.append([])
		for j in grid_height:
			grid[i].append(Vector2i(i, j))
			
	create_grid_layout()
	make_cover()

#reveals an initial clear square to remove the luck based element of the initial click location
func initial_click(coordinates : Vector2i):
	
	var x = coordinates.x
	var y = coordinates.y
	
	while !(is_clear(grid[x][y])) or has_tile_type(grid[x][y], mine_layer_index, spritesheet_mine):
		x += 1
		if x == grid_width:
			x = 0
			y += 1
	
	left_click_handler(Vector2i(x, y))
	
#yeah
func right_click_handler(tile_coordinate: Vector2i) -> void:

	if has_tile_type(tile_coordinate, cover_layer_index, spritesheet_cover):
		
		if !(has_tile_type(tile_coordinate, flag_layer_index,  spritesheet_flag)):
			
			input.emit(tile_coordinate, Inputs.flag)
			set_cell(flag_layer_index, tile_coordinate, final_tile_id, spritesheet_flag)

		else:
			
			input.emit(tile_coordinate, Inputs.unflag)
			erase_cell(flag_layer_index, tile_coordinate)

#checks if a tile has no number
func is_clear(tile_coordinate: Vector2i) -> bool:
	
	return get_cell_atlas_coords(numbers_layer_index, tile_coordinate) == spritesheet_clear_tile

#to make sure that when a tile is manually uncovered it emits signal
func uncover_tile(coordinate: Vector2i) -> void:
	
	if has_tile_type(coordinate, cover_layer_index, spritesheet_cover):
		input.emit(coordinate, Inputs.uncover)
		tile_uncovered.emit()
	erase_cell(cover_layer_index, coordinate)

#recursive function that clears around all adjacent clear cells
func recursive_clear(tile_coordinate : Vector2i) -> void:
		
	for adjacent_tile in get_all_adjacent(tile_coordinate):
		
		if (has_tile_type(adjacent_tile, cover_layer_index, spritesheet_cover)):
			 
			uncover_tile(adjacent_tile)
			erase_cell(flag_layer_index, adjacent_tile)
			if is_clear(adjacent_tile):
				
				recursive_clear(adjacent_tile)

#just called to reveal the board when the game ends

func end_game() -> void:

	clear_layer(cover_layer_index)
	clear_layer(flag_layer_index)

#yeah

func left_click_handler(tile_coordinate : Vector2i) -> void:
	
	if (has_tile_type(tile_coordinate, flag_layer_index,  spritesheet_flag)):
		return
	
	uncover_tile(tile_coordinate)
	
	if has_tile_type(tile_coordinate, mine_layer_index, spritesheet_mine):
		
		lose.emit()
		end_game()
		return
	
	if is_clear(tile_coordinate):
		recursive_clear(tile_coordinate)

#handles inputs

func _input(event):
	
	var tile_position: Vector2i = local_to_map(get_local_mouse_position())
	var mouse_is_on_grid: bool = ((-1 < tile_position.x) and (tile_position.x < grid_width)) and ((-1 < tile_position.y) and (tile_position.y < grid_height))
	if mouse_is_on_grid and (event is InputEventMouseButton):
		if (event.button_index == MOUSE_BUTTON_LEFT) and event.pressed:
			
			left_click_handler(tile_position)
			
		elif (event.button_index == MOUSE_BUTTON_RIGHT) and event.pressed:
			
			right_click_handler(tile_position)
