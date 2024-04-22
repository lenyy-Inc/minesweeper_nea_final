extends Sprite2D

var time_elapsed: int = 0
var lose_emitted: bool

signal digit_1
signal digit_2
signal digit_3
signal lose

var over : bool = false

const child_colour:= Color(10,0,0)

func _ready():
	position = get_parent().timer_position_offset
	get_parent().lose.connect(loss_received)
	get_parent().draw_game.connect(draw_received)
	get_parent().win.connect(win_received)
	get_parent().time_update.connect(update_time)
	
func draw_received(x) -> void:

	digit_1.emit("draw")
	digit_2.emit("draw")
	digit_3.emit("draw")
	over = true

func win_received(x) -> void:
	
	digit_1.emit("win")
	digit_2.emit("win")
	digit_3.emit("win")
	over = true

func loss_received(x) -> void:
	
	digit_1.emit("lose")
	digit_2.emit("lose")
	digit_3.emit("lose")
	over = true

func update_time(time) -> void:

	if over:
		return

	time_elapsed = time

	var digits:= [0, 0, 0]
	var count = 0
	var stringdigits:= str(int(time_elapsed))

	for i in range(stringdigits.length() - 1, -1, -1):
		digits[count] = stringdigits[i]
		count += 1

	digit_1.emit(digits[0])
	digit_2.emit(digits[1])
	digit_3.emit(digits[2])
