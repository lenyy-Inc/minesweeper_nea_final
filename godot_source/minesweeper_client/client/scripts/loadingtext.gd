extends Label

func _ready():
	get_parent().change_text.connect(change_text)

func change_text(new_text) -> void:
	size = get_window().size
	text = new_text

#this keeps the text centred and visible
func _process(delta) -> void:
	size = get_window().size
