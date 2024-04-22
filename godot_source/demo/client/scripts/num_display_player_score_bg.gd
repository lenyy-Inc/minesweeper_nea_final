extends Sprite2D

var score: int = 0

signal digit_1
signal digit_2
signal digit_3

const child_colour:= Color(0,10,0)

var over : bool = false

func _ready():
	position = get_parent().player_score_position_offset
	get_parent().lose.connect(loss_received)
	get_parent().draw_game.connect(draw_received)
	get_parent().win.connect(win_received)
	get_parent().tile_uncovered.connect(update_player_score)

func update_player_score(x, tile_number):

	if over:
		return

	if score >= tile_number:
		return
	
	score = tile_number
	
	var stringdigits:= str(score)
	var digits:= [0, 0, 0]
	var count = 0

	for i in range(stringdigits.length() - 1, -1, -1):
		digits[count] = stringdigits[i]
		count += 1

	digit_1.emit(digits[0])
	digit_2.emit(digits[1])
	digit_3.emit(digits[2])

func draw_received(x) -> void:

	digit_1.emit("draw")
	digit_2.emit("draw")
	digit_3.emit("draw")
	over = true


func loss_received(x) -> void:

	digit_1.emit("lose")
	digit_2.emit("lose")
	digit_3.emit("lose")
	over = true

func win_received(x) -> void:
	
	digit_1.emit("win")
	digit_2.emit("win")
	digit_3.emit("win")
	over = true
