extends Node

var time_elapsed : float = 0
var player_number: int = 0
var demo_JSON
var keys : Array

var mine_coords:= []
var initial_click_location : Vector2i
var mine_number: int 
var grid_width: int 
var grid_height: int 

var over: bool = false

signal input
signal win
signal draw
signal lose
signal opponent_tile_uncovered
signal time_update

var window = JavaScriptBridge.get_interface("window")

func pass_input(player, coordinate, input_type) -> void:
	input.emit(player, coordinate, input_type)

func pass_tile_uncovered(sender, tiles_uncovered) -> void:
	opponent_tile_uncovered.emit(sender, tiles_uncovered)

func pass_draw(sender) -> void:
	if over == true:
		return
	over = true
	draw.emit(sender)

func pass_win(sender) -> void:
	if over == true:
		return
	over = true
	win.emit(sender)

func pass_lose(sender) -> void:
	if over == true:
		return
	over = true
	lose.emit(sender)

func initialise_game() -> void:

	var child_board_1 = preload("res://client/scenes/minesweeper_tiled_board.tscn").instantiate()
	add_child(child_board_1)
	child_board_1.lose.connect(pass_lose)
	child_board_1.win.connect(pass_win)
	child_board_1.tile_uncovered.connect(pass_tile_uncovered)
	
	player_number += 1
	
	var child_board_2 = preload("res://client/scenes/minesweeper_tiled_board.tscn").instantiate()
	add_child(child_board_2)
	child_board_2.lose.connect(pass_lose)
	child_board_2.win.connect(pass_win)
	child_board_2.tile_uncovered.connect(pass_tile_uncovered)

func _process(delta : float) -> void:
	time_elapsed += delta
	time_update.emit(time_elapsed)

	if keys.size() == 0:
		await get_tree().create_timer(3.0).timeout
		draw.emit(2)

	for key in keys:
		if key < time_elapsed:
			var demo_input = demo_JSON[str(key)]
			var input_type = demo_input["input"]
			var input_coords = Vector2i(int(demo_input["x"]),int(demo_input["y"]))
			if demo_input["player"] == "player_1":
				pass_input(1, input_coords, input_type)
			else:
				pass_input(0, input_coords, input_type)
			keys.remove_at(0)
		else:
			return

func _ready() -> void:
	#var demo_string = window.demo
	var demo_string = '{"10.0819519999999":{"input":1,"player":"player_1","x":15,"y":13},"11.7507839999998":{"input":1,"player":"player_1","x":6,"y":12},"111.577417999974":{"input":0,"player":"player_1","x":13,"y":5},"112.825593999974":{"input":1,"player":"player_1","x":14,"y":5},"114.087561999973":{"input":1,"player":"player_1","x":12,"y":5},"114.866809999973":{"input":0,"player":"player_1","x":15,"y":5},"115.873625999973":{"input":0,"player":"player_1","x":15,"y":4},"116.708041999972":{"input":0,"player":"player_1","x":14,"y":4},"116.998642888861":{"input":0,"player":"player_1","x":14,"y":3},"117.276420666639":{"input":0,"player":"player_1","x":15,"y":3},"117.894153999972":{"input":0,"player":"player_1","x":13,"y":4},"118.294121999972":{"input":0,"player":"player_1","x":13,"y":3},"118.307913999972":{"input":0,"player":"player_1","x":12,"y":2},"118.321705999972":{"input":0,"player":"player_1","x":11,"y":1},"118.335497999972":{"input":0,"player":"player_1","x":10,"y":0},"118.349289999972":{"input":0,"player":"player_1","x":11,"y":0},"118.363081999972":{"input":0,"player":"player_1","x":12,"y":0},"118.376873999972":{"input":0,"player":"player_1","x":13,"y":0},"118.390665999972":{"input":0,"player":"player_1","x":14,"y":0},"118.404457999972":{"input":0,"player":"player_1","x":12,"y":1},"118.418249999972":{"input":0,"player":"player_1","x":13,"y":1},"118.432041999972":{"input":0,"player":"player_1","x":14,"y":1},"118.445833999972":{"input":0,"player":"player_1","x":13,"y":2},"118.459625999972":{"input":0,"player":"player_1","x":14,"y":2},"118.473417999972":{"input":0,"player":"player_1","x":12,"y":3},"118.487209999972":{"input":0,"player":"player_1","x":11,"y":2},"118.501001999972":{"input":0,"player":"player_1","x":10,"y":1},"118.514793999972":{"input":0,"player":"player_1","x":10,"y":2},"118.528585999972":{"input":0,"player":"player_1","x":10,"y":3},"118.542377999972":{"input":0,"player":"player_1","x":9,"y":2},"118.556169999972":{"input":0,"player":"player_1","x":9,"y":3},"118.569961999972":{"input":0,"player":"player_1","x":11,"y":3},"118.583753999972":{"input":0,"player":"player_1","x":10,"y":4},"118.597545999972":{"input":0,"player":"player_1","x":11,"y":4},"118.611337999972":{"input":0,"player":"player_1","x":12,"y":4},"118.625129999972":{"input":0,"player":"player_1","x":9,"y":4},"121.866249999971":{"input":0,"player":"player_1","x":11,"y":5},"123.57645799997":{"input":1,"player":"player_1","x":10,"y":5},"124.72119399997":{"input":0,"player":"player_1","x":9,"y":5},"127.058937999969":{"input":0,"player":"player_1","x":8,"y":5},"127.810601999968":{"input":1,"player":"player_1","x":8,"y":4},"128.400879777747":{"input":1,"player":"player_1","x":8,"y":3},"130.044905999972":{"input":0,"player":"player_1","x":8,"y":2},"131.472377999974":{"input":1,"player":"player_1","x":9,"y":1},"132.810201999977":{"input":0,"player":"player_1","x":9,"y":0},"133.265337999978":{"input":0,"player":"player_1","x":8,"y":0},"133.782537999978":{"input":0,"player":"player_1","x":8,"y":1},"139.685722999989":{"input":1,"player":"player_1","x":7,"y":5},"14.0402559999996":{"input":0,"player":"player_1","x":6,"y":13},"140.65805899999":{"input":0,"player":"player_1","x":7,"y":4},"15.6470239999994":{"input":1,"player":"player_1","x":4,"y":13},"15.9297599999994":{"input":1,"player":"player_1","x":5,"y":13},"151.92612300001":{"input":0,"player":"player_1","x":6,"y":5},"17.0948279999992":{"input":0,"player":"player_1","x":6,"y":14},"17.4261919999992":{"input":0,"player":"player_1","x":7,"y":14},"17.9433919999993":{"input":0,"player":"player_1","x":5,"y":14},"175.062203000049":{"input":0,"player":"player_1","x":7,"y":2},"189.681723000074":{"input":1,"player":"player_1","x":4,"y":5},"19.3294879999995":{"input":1,"player":"player_1","x":8,"y":14},"190.102379000075":{"input":1,"player":"player_1","x":5,"y":5},"192.88146700008":{"input":0,"player":"player_1","x":3,"y":5},"195.632971000084":{"input":0,"player":"player_1","x":2,"y":5},"197.984151000089":{"input":0,"player":"player_1","x":2,"y":4},"198.349995000089":{"input":0,"player":"player_1","x":3,"y":4},"198.68789900009":{"input":0,"player":"player_1","x":4,"y":4},"199.577483000091":{"input":0,"player":"player_1","x":2,"y":3},"199.880907000092":{"input":0,"player":"player_1","x":3,"y":3},"20.6397279999997":{"input":0,"player":"player_1","x":9,"y":14},"200.211915000092":{"input":0,"player":"player_1","x":4,"y":3},"21.2327839999998":{"input":1,"player":"player_1","x":10,"y":14},"21.8947999999999":{"input":0,"player":"player_1","x":8,"y":15},"22.13616":{"input":0,"player":"player_1","x":9,"y":15},"22.398208":{"input":0,"player":"player_1","x":10,"y":15},"23.0188480000001":{"input":0,"player":"player_1","x":7,"y":15},"23.7774080000003":{"input":0,"player":"player_1","x":6,"y":15},"23.7912000000003":{"input":0,"player":"player_1","x":5,"y":15},"23.8049920000003":{"input":0,"player":"player_1","x":4,"y":14},"23.8187840000003":{"input":0,"player":"player_1","x":4,"y":15},"246.198270111282":{"input":1,"player":"player_1","x":15,"y":2},"246.538547889061":{"input":1,"player":"player_1","x":15,"y":1},"246.946107000173":{"input":0,"player":"player_1","x":15,"y":0},"254.235179000185":{"input":0,"player":"player_1","x":6,"y":2},"261.896635000175":{"input":0,"player":"player_1","x":6,"y":1},"262.413835000174":{"input":0,"player":"player_1","x":6,"y":3},"265.903211000165":{"input":0,"player":"player_1","x":6,"y":0},"268.26853900016":{"input":0,"player":"player_1","x":5,"y":0},"268.28233100016":{"input":0,"player":"player_1","x":4,"y":0},"268.29612300016":{"input":0,"player":"player_1","x":3,"y":0},"268.309915000159":{"input":0,"player":"player_1","x":2,"y":0},"268.323707000159":{"input":0,"player":"player_1","x":1,"y":0},"268.337499000159":{"input":0,"player":"player_1","x":0,"y":0},"268.351291000159":{"input":0,"player":"player_1","x":0,"y":1},"268.365083000159":{"input":0,"player":"player_1","x":1,"y":1},"268.378875000159":{"input":0,"player":"player_1","x":2,"y":1},"268.392667000159":{"input":0,"player":"player_1","x":3,"y":1},"268.406459000159":{"input":0,"player":"player_1","x":4,"y":1},"268.420251000159":{"input":0,"player":"player_1","x":5,"y":1},"268.434139889048":{"input":0,"player":"player_1","x":4,"y":2},"268.448028777937":{"input":0,"player":"player_1","x":5,"y":2},"27.0047360000008":{"input":0,"player":"player_1","x":3,"y":13},"27.5081440000009":{"input":1,"player":"player_1","x":2,"y":13},"274.454251000149":{"input":1,"player":"player_1","x":3,"y":2},"275.130059000147":{"input":0,"player":"player_1","x":2,"y":2},"276.047227000145":{"input":0,"player":"player_1","x":1,"y":2},"276.385131000144":{"input":0,"player":"player_1","x":1,"y":3},"277.847083000141":{"input":1,"player":"player_1","x":0,"y":2},"278.453931000139":{"input":0,"player":"player_1","x":0,"y":3},"280.260683000135":{"input":1,"player":"player_1","x":1,"y":4},"281.301979000132":{"input":0,"player":"player_1","x":0,"y":4},"282.543259000134":{"input":0,"player":"player_1","x":0,"y":5},"282.874267000133":{"input":0,"player":"player_1","x":1,"y":5},"284.639643000129":{"input":0,"player":"player_1","x":1,"y":6},"285.398203000127":{"input":0,"player":"player_1","x":0,"y":6},"291.873547000111":{"input":1,"player":"player_1","x":5,"y":3},"296.493867000104":{"input":0,"player":"player_1","x":5,"y":4},"297.859275000101":{"input":1,"player":"player_1","x":6,"y":4},"300.548715000094":{"input":1,"player":"player_1","x":7,"y":3},"302.017563000091":{"input":0,"player":"player_1","x":7,"y":1},"302.44511500009":{"input":1,"player":"player_1","x":7,"y":0},"33.6524800000006":{"input":1,"player":"player_1","x":10,"y":7},"34.2179520000004":{"input":0,"player":"player_1","x":10,"y":6},"34.9627200000002":{"input":0,"player":"player_1","x":9,"y":7},"343.780271000006":{"input":0,"player":"player_1","x":1,"y":11},"37.3694239999993":{"input":0,"player":"player_1","x":8,"y":7},"37.7349119999992":{"input":0,"player":"player_1","x":8,"y":6},"38.0038559999991":{"input":0,"player":"player_1","x":9,"y":6},"39.2589279999987":{"input":1,"player":"player_1","x":7,"y":7},"39.7702493333318":{"input":0,"player":"player_1","x":7,"y":6},"4.95822400000003":{"input":1,"player":"player_1","x":6,"y":11},"40.6174399999983":{"input":0,"player":"player_1","x":6,"y":7},"42.9207039999975":{"input":0,"player":"player_1","x":5,"y":7},"45.7204799999965":{"input":0,"player":"player_1","x":4,"y":7},"46.7824639999961":{"input":0,"player":"player_1","x":3,"y":7},"47.3203519999959":{"input":0,"player":"player_1","x":3,"y":6},"47.6375679999958":{"input":0,"player":"player_1","x":4,"y":6},"48.0513279999957":{"input":0,"player":"player_1","x":5,"y":6},"5.44784000000004":{"input":0,"player":"player_1","x":5,"y":11},"5.72368000000005":{"input":0,"player":"player_1","x":5,"y":10},"50.3614879999949":{"input":1,"player":"player_1","x":6,"y":6},"56.9126879999927":{"input":1,"player":"player_1","x":14,"y":7},"57.2714179999926":{"input":0,"player":"player_1","x":14,"y":6},"57.6989699999924":{"input":0,"player":"player_1","x":15,"y":7},"58.5333859999921":{"input":0,"player":"player_1","x":15,"y":6},"6.04089600000006":{"input":0,"player":"player_1","x":5,"y":9},"6.79256000000009":{"input":1,"player":"player_1","x":5,"y":8},"62.146889999991":{"input":0,"player":"player_1","x":11,"y":14},"63.3123139999906":{"input":0,"player":"player_1","x":11,"y":15},"63.6019459999905":{"input":0,"player":"player_1","x":12,"y":15},"63.9260579999904":{"input":0,"player":"player_1","x":12,"y":14},"64.7742659999901":{"input":1,"player":"player_1","x":13,"y":14},"65.2569859999899":{"input":0,"player":"player_1","x":14,"y":14},"66.6086019999894":{"input":0,"player":"player_1","x":15,"y":14},"68.5050019999887":{"input":0,"player":"player_1","x":13,"y":15},"70.4819314444326":{"input":0,"player":"player_1","x":14,"y":15},"70.870329999988":{"input":1,"player":"player_1","x":15,"y":15},"77.5249699999857":{"input":1,"player":"player_1","x":2,"y":7},"79.0903619999851":{"input":1,"player":"player_1","x":2,"y":6},"8.17865600000011":{"input":0,"player":"player_1","x":4,"y":9},"8.44760000000009":{"input":0,"player":"player_1","x":4,"y":10},"8.46139200000009":{"input":0,"player":"player_1","x":3,"y":9},"8.47518400000009":{"input":0,"player":"player_1","x":2,"y":8},"8.48897600000008":{"input":0,"player":"player_1","x":3,"y":8},"8.50276800000008":{"input":0,"player":"player_1","x":4,"y":8},"8.51656000000008":{"input":0,"player":"player_1","x":2,"y":9},"8.53035200000008":{"input":0,"player":"player_1","x":2,"y":10},"8.54414400000008":{"input":0,"player":"player_1","x":3,"y":10},"8.55793600000008":{"input":0,"player":"player_1","x":2,"y":11},"8.57172800000008":{"input":0,"player":"player_1","x":3,"y":11},"8.58552000000008":{"input":0,"player":"player_1","x":4,"y":11},"8.59931200000007":{"input":0,"player":"player_1","x":3,"y":12},"8.61310400000007":{"input":0,"player":"player_1","x":4,"y":12},"8.62689600000007":{"input":0,"player":"player_1","x":5,"y":12},"8.64068800000007":{"input":0,"player":"player_1","x":2,"y":12},"grid_height":16,"grid_width":16,"mine_coords":["(4, 5)","(1, 4)","(1, 12)","(14, 5)","(3, 14)","(13, 14)","(2, 6)","(5, 3)","(2, 7)","(1, 11)","(14, 7)","(3, 2)","(6, 12)","(0, 7)","(9, 1)","(5, 5)","(6, 6)","(8, 3)","(6, 11)","(7, 3)","(10, 5)","(15, 13)","(10, 7)","(15, 1)","(1, 9)","(15, 15)","(5, 8)","(7, 5)","(7, 0)","(2, 13)","(12, 5)","(4, 13)","(15, 2)","(7, 7)","(10, 14)","(8, 14)","(6, 4)","(0, 2)","(5, 13)","(8, 4)","(3, 8)"],"mine_number":40}'
	demo_JSON = JSON.parse_string(demo_string)
	
	keys = demo_JSON.keys()
	
	keys.remove_at(keys.size() - 1)
	keys.remove_at(keys.size() - 1)
	keys.remove_at(keys.size() - 1)
	keys.remove_at(keys.size() - 1)

	for i in range(0, keys.size()):
		keys[i] = float(keys[i])
		
	keys.sort()
	
	mine_coords = demo_JSON["mine_coords"]
	print(mine_coords)
	var count: int = 0
	
	var current_coords_x = ""
	var current_coords_y = ""
	var looking_at_x : bool = true
	
	for i in mine_coords.size():
		for j in mine_coords[i].length():
			match mine_coords[i][j]:

				",":

					looking_at_x = false
			
				")":

					looking_at_x = true
					mine_coords[i] = Vector2i(int(current_coords_x), int(current_coords_y))

					current_coords_x = ""
					current_coords_y = ""

				" ":
				
					pass
				
				"(":
				
					pass

				_:

					if looking_at_x:
						current_coords_x += str(mine_coords[i][j])
					else:
						current_coords_y += str(mine_coords[i][j])
	

	initial_click_location = mine_coords[mine_coords.size() - 1]
	mine_coords.remove_at(mine_coords.size() - 1)
	print(mine_coords)

	grid_height = int(demo_JSON["grid_height"])
	grid_width = int(demo_JSON["grid_width"])
	
	initialise_game()

