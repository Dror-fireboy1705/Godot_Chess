extends Sprite2D

const BOARD_SIZE = 8
const CELL_WIDTH = 18

const TEXTURE_HOLDER = preload("res://Scenes/texture_holder.tscn")

const BLACK_KING = preload("res://assets/black_king.png")
const BLACK_KNIGHT = preload("res://assets/black_knight.png")
const BLACK_BISHOP = preload("res://assets/black_bishop.png")
const BLACK_PAWN = preload("res://assets/black_pawn.png")
const BLACK_QUEEN = preload("res://assets/black_queen.png")
const BLACK_ROOK = preload("res://assets/black_rook.png")
const CHESS_BOARD = preload("res://assets/Chess_board.png")
const WHITE_BISHOP = preload("res://assets/white_bishop.png")
const WHITE_KING = preload("res://assets/white_king.png")
const WHITE_KNIGHT = preload("res://assets/white_knight.png")
const WHITE_PAWN = preload("res://assets/white_pawn.png")
const WHITE_QUEEN = preload("res://assets/white_queen.png")
const WHITE_ROOK = preload("res://assets/white_rook.png")

const TURN_BLACK = preload("res://assets/turn-black.png")
const TURN_WHITE = preload("res://assets/turn-white.png")
const PIECE_MOVE = preload("res://assets/Piece_move.png")

const BLACK_CHECKMATE = preload("res://assets/black_checkmate.png")
const WHITE_CHECKMATE = preload("res://assets/white_checkmate.png")
const STALEMATE = preload("res://assets/stalemate.png")
const RESTART = preload("res://assets/restart.png")

const BLACK_KING_IN_CHECK = preload("res://assets/black_king_in-check.png")
const WHITE_KING_IN_CHECK = preload("res://assets/white_king_in-check.png")
const CHOSEN_PIECE = preload("res://assets/chosen_piece.png")

@onready var pieces: Node2D = $Pieces
@onready var dots: Node2D = $Dots
@onready var turn: Sprite2D = $Turn
@onready var white_pieces: Control = $"../CanvasLayer/white_pieces"
@onready var black_pieces: Control = $"../CanvasLayer/black_pieces"
@onready var win_message: Sprite2D = $Win_message
@onready var restart: Button = $"../CanvasLayer/Restart"


#variables
# -6 = black king
# -5 = black queen
# -4 = black rook
# -3 = black bishop
# -2 = black knight
# -1 = black pawn
# 0 = empty
# 1 = white pawn
# 2 = white knight
# 3 = white bishop
# 4 = white rook
# 5 = white queen
# 6 = white king

var board : Array
var white : bool = true
var state : bool = false
var moves = []
var selected_piece : Vector2

var promotion_square = null

var white_castle_left = false
var white_castle_right = false
var black_castle_left = false
var black_castle_right = false

var en_passant = null

var white_king_pos = Vector2(0,4)
var black_king_pos = Vector2(7,4)

var fifty_move_rule = 0

var unique_board_moves : Array = []
var amount_of_same : Array = []

func _ready():
	board.append([4,2,3,5,6,3,2,4])
	board.append([1,1,1,1,1,1,1,1])
	board.append([0,0,0,0,0,0,0,0])
	board.append([0,0,0,0,0,0,0,0])
	board.append([0,0,0,0,0,0,0,0])
	board.append([0,0,0,0,0,0,0,0])
	board.append([-1,-1,-1,-1,-1,-1,-1,-1])
	board.append([-4,-2,-3,-5,-6,-3,-2,-4])
	
	display_board()
	
	#win_message = null
	
	var white_buttons = get_tree().get_nodes_in_group("white_pieces")
	var black_buttons = get_tree().get_nodes_in_group("black_pieces")
	
	for button in white_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))
	
	for button in black_buttons:
		button.pressed.connect(self._on_button_pressed.bind(button))
	
	var restart_button = get_node("../CanvasLayer/Restart")
	restart_button.pressed.connect(self.restart_pressed.bind())

func _input(event):
	if event is InputEventMouseButton && event.pressed && promotion_square == null:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_out(): return
			var var1 = snapped(get_global_mouse_position().x, 0)/CELL_WIDTH
			var var2 = abs(snapped(get_global_mouse_position().y, 0))/CELL_WIDTH
			if !state && ((white && board[var2][var1] > 0) || (!white && board[var2][var1] < 0)):
				selected_piece = Vector2(var2,var1)
				show_options()
				state = true
			elif state: set_move(var2, var1)

func is_mouse_out():
	if get_rect().has_point(to_local(get_global_mouse_position())): return false
	return true

func display_board():
	for child in pieces.get_children():
		child.queue_free()
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			var holder = TEXTURE_HOLDER.instantiate()
			pieces.add_child(holder)
			holder.global_position = Vector2(j*CELL_WIDTH+(CELL_WIDTH/2), -i*CELL_WIDTH-(CELL_WIDTH/2))
			
			match board[i][j]:
				-6:
					if !white && is_in_check(black_king_pos): holder.texture = BLACK_KING_IN_CHECK
					else: holder.texture = BLACK_KING
				-5: holder.texture = BLACK_QUEEN
				-4: holder.texture = BLACK_ROOK
				-3: holder.texture = BLACK_BISHOP
				-2: holder.texture = BLACK_KNIGHT
				-1: holder.texture = BLACK_PAWN
				0: holder.texture = null
				1: holder.texture = WHITE_PAWN
				2: holder.texture = WHITE_KNIGHT
				3: holder.texture = WHITE_BISHOP
				4: holder.texture = WHITE_ROOK
				5: holder.texture = WHITE_QUEEN
				6:
					if white && is_in_check(white_king_pos): holder.texture = WHITE_KING_IN_CHECK
					else: holder.texture = WHITE_KING
	
	if white: turn.texture = TURN_WHITE
	else: turn.texture = TURN_BLACK


func show_options():
	moves = get_moves(selected_piece)
	if moves == []:
		state = false
		return
	show_dots()

func show_dots():
	for i in moves:
		var holder = TEXTURE_HOLDER.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.global_position = Vector2(i.y*CELL_WIDTH+(CELL_WIDTH/2), -i.x*CELL_WIDTH-(CELL_WIDTH/2))
	
	var holder = TEXTURE_HOLDER.instantiate()
	dots.add_child(holder)
	holder.texture = CHOSEN_PIECE
	holder.global_position = Vector2(selected_piece.y*CELL_WIDTH+(CELL_WIDTH/2), -selected_piece.x*CELL_WIDTH-(CELL_WIDTH/2))

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(var2, var1):
	var just_now = false
	for i in moves:
		if i.x == var2 && i.y == var1:
			fifty_move_rule += 1
			if is_enemy(Vector2(var2, var1)): fifty_move_rule = 0
			match board[selected_piece.x][selected_piece.y]:
				1:
					fifty_move_rule = 0
					if i.x == 7: promote(i)
					if i.x == 3 && selected_piece.x == 1:
						en_passant = i
						just_now = true
					elif en_passant != null:
						if en_passant.y == i.y && selected_piece.y != i.y && selected_piece.x == en_passant.x:
							board[en_passant.x][en_passant.y] = 0
				-1:
					fifty_move_rule = 0
					if i.x == 0: promote(i)
					if i.x == 4 && selected_piece.x == 6:
						en_passant = i
						just_now = true
					elif en_passant != null:
						if en_passant.y == i.y && selected_piece.y != i.y && selected_piece.x == en_passant.x:
							board[en_passant.x][en_passant.y] = 0
				4:
					if selected_piece.x == 0 && selected_piece.y == 0:
						white_castle_left = true
					elif selected_piece.x == 0 && selected_piece.y == 7:
						white_castle_right = true
				-4:
					if selected_piece.x == 7 && selected_piece.y == 0:
						black_castle_left = true
					elif selected_piece.x == 7 && selected_piece.y == 7:
						black_castle_right = true
				6:
					if selected_piece.x == 0 && selected_piece.y == 4:
						white_castle_left = true
						white_castle_right = true
						if i.y == 2:
							board[0][0] = 0
							board[0][3] = 4
						elif i.y == 6:
							board[0][7] = 0
							board[0][5] = 4
					white_king_pos = i
				-6:
					if selected_piece.x == 7 && selected_piece.y == 4:
						black_castle_left = true
						black_castle_right = true
						if i.y == 2:
							board[7][0] = 0
							board[7][3] = -4
						elif i.y == 6:
							board[7][7] = 0
							board[7][5] = -4
					black_king_pos = i
			if !just_now: en_passant = null
			board[var2][var1] = board[selected_piece.x][selected_piece.y]
			board[selected_piece.x][selected_piece.y] = 0
			white = !white
			threefold_position()
			display_board()
			break
	delete_dots()
	state = false
	
	if (selected_piece.x != var2 || selected_piece.y != var1) && ((white && board[var2][var1] > 0) || (!white && board[var2][var1] < 0)):
		selected_piece = Vector2(var2, var1)
		show_options()
		state = true
	elif is_stalemate():
		if white && is_in_check(white_king_pos):
			win_message.texture = BLACK_CHECKMATE
			restart.visible = true
		elif !white && is_in_check(black_king_pos):
			win_message.texture = WHITE_CHECKMATE
			restart.visible = true
		else:
			win_message.texture = STALEMATE
			restart.visible = true
	
	if fifty_move_rule == 50:
		win_message.texture = STALEMATE
		restart.visible = true
	if insufficient_material():
		win_message.texture = STALEMATE
		restart.visible = true

func get_moves(selected : Vector2):
	var _moves = []
	match abs(board[selected.x][selected.y]):
		1: _moves = get_pawn_moves(selected)
		2: _moves = get_knight_moves(selected)
		3: _moves = get_bishop_moves(selected)
		4: _moves = get_rook_moves(selected)
		5: _moves = get_rook_moves(selected) + get_bishop_moves(selected) #queen moves like rook or bishop
		6: _moves = get_king_moves(selected)
	return _moves

func get_rook_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0)]
	
	for i in directions:
		var pos = piece_position
		pos += i
		while is_valid_position(pos):
			if is_empty(pos):
				var temp = board[piece_position.x][piece_position.y]
				board[pos.x][pos.y] = temp
				board[piece_position.x][piece_position.y] = 0
				if (white && !is_in_check(white_king_pos)) || (!white && !is_in_check(black_king_pos)): _moves.append(pos)
				board[piece_position.x][piece_position.y] = temp
				board[pos.x][pos.y] = 0
			elif is_enemy(pos):
				var temp = board[pos.x][pos.y]
				board[pos.x][pos.y] = board[piece_position.x][piece_position.y]
				board[piece_position.x][piece_position.y] = 0
				if (white && !is_in_check(white_king_pos)) || (!white && !is_in_check(black_king_pos)): _moves.append(pos)
				board[piece_position.x][piece_position.y] = board[pos.x][pos.y]
				board[pos.x][pos.y] = temp
				break
			else: break
			
			pos += i
	
	return _moves

func get_bishop_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]
	
	for i in directions:
		var pos = piece_position
		pos += i
		while is_valid_position(pos):
			if is_empty(pos):
				var temp = board[piece_position.x][piece_position.y]
				board[pos.x][pos.y] = temp
				board[piece_position.x][piece_position.y] = 0
				if (white && !is_in_check(white_king_pos)) || (!white && !is_in_check(black_king_pos)):
					_moves.append(pos)
				board[piece_position.x][piece_position.y] = temp
				board[pos.x][pos.y] = 0
			elif is_enemy(pos):
				var temp = board[pos.x][pos.y]
				board[pos.x][pos.y] = board[piece_position.x][piece_position.y]
				board[piece_position.x][piece_position.y] = 0
				if (white && !is_in_check(white_king_pos)) || (!white && !is_in_check(black_king_pos)):
					_moves.append(pos)
				board[piece_position.x][piece_position.y] = board[pos.x][pos.y]
				board[pos.x][pos.y] = temp
				break
			else: break
			
			pos += i
	
	return _moves

func get_knight_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(1,2), Vector2(1,-2), Vector2(-1,2), Vector2(-1,-2),
	Vector2(2,1), Vector2(2,-1), Vector2(-2,1), Vector2(-2,-1)]
	
	for i in directions:
		var pos = piece_position + i
		if is_valid_position(pos):
			if is_empty(pos):
				board[pos.x][pos.y] = 2 if white else -2
				board[piece_position.x][piece_position.y] = 0
				if (white && !is_in_check(white_king_pos)) || (!white && !is_in_check(black_king_pos)):
					_moves.append(pos)
				board[piece_position.x][piece_position.y] = 2 if white else -2
				board[pos.x][pos.y] = 0
			elif is_enemy(pos):
				var temp = board[pos.x][pos.y]
				board[pos.x][pos.y] = 2 if white else -2
				board[piece_position.x][piece_position.y] = 0
				if (white && !is_in_check(white_king_pos)) || (!white && !is_in_check(black_king_pos)):
					_moves.append(pos)
				board[piece_position.x][piece_position.y] = 2 if white else -2
				board[pos.x][pos.y] = temp
	
	return _moves

func get_king_moves(piece_position : Vector2):
	var _moves = []
	var directions = [Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0),
	Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]
	
	if white:
		board[white_king_pos.x][white_king_pos.y] = 0
	else:
		board[black_king_pos.x][black_king_pos.y] = 0
	
	for i in directions:
		var pos = piece_position + i
		if is_valid_position(pos):
			if !is_in_check(pos):
				if is_empty(pos): _moves.append(pos)
				elif is_enemy(pos): _moves.append(pos)
	#castling
	if white:
		if !white_castle_left && is_empty(Vector2(0,1)) && is_empty(Vector2(0,2)) && !is_in_check(Vector2(0,2)) && is_empty(Vector2(0,3)) && !is_in_check(Vector2(0,3)) && !is_in_check(Vector2(0,4)):
			_moves.append(Vector2(0,2))
		if !white_castle_right && !is_in_check(Vector2(0,4)) && is_empty(Vector2(0,5)) && is_empty(Vector2(0,6)) && !is_in_check(Vector2(0,5)) && !is_in_check(Vector2(0,6)):
			_moves.append(Vector2(0,6))
	else:
		if !black_castle_left && is_empty(Vector2(7,1)) && is_empty(Vector2(7,2)) && !is_in_check(Vector2(7,2)) && is_empty(Vector2(7,3)) && !is_in_check(Vector2(7,3)) && !is_in_check(Vector2(7,4)):
			_moves.append(Vector2(7,2))
		if !black_castle_right && !is_in_check(Vector2(7,4)) && is_empty(Vector2(7,5)) && is_empty(Vector2(7,6)) && !is_in_check(Vector2(7,5)) && !is_in_check(Vector2(7,6)):
			_moves.append(Vector2(7,6))
	
	if white:
		board[white_king_pos.x][white_king_pos.y] = 6
	else:
		board[black_king_pos.x][black_king_pos.y] = -6
	
	return _moves

func get_pawn_moves(piece_position : Vector2):
	var _moves = []
	var direction
	var is_first_move = false
	
	if white: direction = Vector2(1,0)
	else: direction = Vector2(-1,0)
	
	if (white && piece_position.x == 1) || (!white && piece_position.x == 6): is_first_move = true
	
	if en_passant != null && ((white && piece_position.x == 4) || (!white && piece_position.x == 3)) && abs(en_passant.y - piece_position.y) == 1:
		var pos = en_passant + direction
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		board[en_passant.x][en_passant.y] = 0
		if (white && !is_in_check(white_king_pos)) || (!white && !is_in_check(black_king_pos)):
			_moves.append(pos)
		board[piece_position.x][piece_position.y] = 1 if white else -1
		board[pos.x][pos.y] = 0
		board[en_passant.x][en_passant.y] = -1 if white else 1
	
	var pos = piece_position + direction
	if is_empty(pos):
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		if (white && !is_in_check(white_king_pos)) || (!white && !is_in_check(black_king_pos)):
			_moves.append(pos)
		board[piece_position.x][piece_position.y] = 1 if white else -1
		board[pos.x][pos.y] = 0
	
	pos += Vector2(0,1)
	if is_valid_position(pos) && is_enemy(pos):
		var temp = board[pos.x][pos.y]
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		if (white && !is_in_check(white_king_pos)) || (!white && !is_in_check(black_king_pos)):
			_moves.append(pos)
		board[piece_position.x][piece_position.y] = 1 if white else -1
		board[pos.x][pos.y] = temp
	pos -= Vector2(0,1)
	
	pos += Vector2(0,-1)
	if is_valid_position(pos) && is_enemy(pos):
		var temp = board[pos.x][pos.y]
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		if (white && !is_in_check(white_king_pos)) || (!white && !is_in_check(black_king_pos)):
			_moves.append(pos)
		board[piece_position.x][piece_position.y] = 1 if white else -1
		board[pos.x][pos.y] = temp
	pos -= Vector2(0,-1)
	
	pos += direction
	if is_first_move && is_empty(pos) && is_empty(pos-direction):
		board[pos.x][pos.y] = 1 if white else -1
		board[piece_position.x][piece_position.y] = 0
		if (white && !is_in_check(white_king_pos)) || (!white && !is_in_check(black_king_pos)):
			_moves.append(pos)
		board[piece_position.x][piece_position.y] = 1 if white else -1
		board[pos.x][pos.y] = 0
	
	return _moves

func is_valid_position(pos : Vector2):
	if pos.x >= 0 && pos.x < BOARD_SIZE && pos.y >= 0 && pos.y < BOARD_SIZE: return true
	return false

func is_empty(pos : Vector2):
	if board[pos.x][pos.y] == 0: return true
	return false

func is_enemy(pos : Vector2):
	if (white && board[pos.x][pos.y] < 0) || (!white && board[pos.x][pos.y] > 0): return true

func promote(_var : Vector2):
	promotion_square = _var
	white_pieces.visible = white
	black_pieces.visible = !white

func _on_button_pressed(button):
	var num_char = int(button.name.substr(0,1))
	board[promotion_square.x][promotion_square.y] = -num_char if white else num_char
	white_pieces.visible = false
	black_pieces.visible = false
	promotion_square = null
	display_board()

func is_in_check(king_pos : Vector2):
	var directions = [Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0),
	Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]
	
	var pawn_direction = 1 if white else -1
	var pawn_attacks = [
		king_pos + Vector2(pawn_direction, 1),
		king_pos + Vector2(pawn_direction, -1)]
	
	for i in pawn_attacks:
		if is_valid_position(i):
			if (white && board[i.x][i.y] == -1) || (!white && board[i.x][i.y] == 1): return true
	
	for i in directions:
		var pos = king_pos + i
		if is_valid_position(pos):
			if (white && board[pos.x][pos.y] == -6) || (!white && board[pos.x][pos.y] == 6): return true
	
	for i in directions:
		var pos = king_pos + i
		while is_valid_position(pos):
			if !is_empty(pos):
				var piece = board[pos.x][pos.y]
				if (i.x == 0 || i.y == 0) && ((white && piece in [-4, -5]) || (!white && piece in [4, 5])): return true
				elif (i.x != 0 && i.y != 0) && ((white && piece in [-3, -5]) || (!white && piece in [3, 5])): return true
				break
			pos += i
	
	var knight_directions = [Vector2(1,2), Vector2(1,-2), Vector2(-1,2), Vector2(-1,-2),
	Vector2(2,1), Vector2(2,-1), Vector2(-2,1), Vector2(-2,-1)]
	
	for i in knight_directions:
		var pos = king_pos + i
		if is_valid_position(pos):
			if (white && board[pos.x][pos.y] == -2) || (!white && board[pos.x][pos.y] == 2): return true
	
	return false

func is_stalemate():
	if white:
		for i in BOARD_SIZE:
			for j in BOARD_SIZE:
				if board[i][j] > 0:
					if get_moves(Vector2(i,j)) != []: return false
	else:
		for i in BOARD_SIZE:
			for j in BOARD_SIZE:
				if board[i][j] < 0:
					if get_moves(Vector2(i,j)) != []: return false
	return true

func insufficient_material():
	var white_count = 0
	var black_count = 0
	
	for i in BOARD_SIZE:
		for j in BOARD_SIZE:
			match board[i][j]:
				2, 3:
					if white_count == 0: white_count += 1
					else: return false
				-2, -3:
					if black_count == 0: black_count += 1
					else: return false
				6, -6, 0: pass
				_: return false #1, -1, 4, -4, 5, -5
	return true

func threefold_position():
	for i in unique_board_moves.size():
		if board == unique_board_moves[i]:
			amount_of_same[i] += 1
			if amount_of_same[i] >= 3:
				win_message.texture = STALEMATE
				restart.visible = true
			return
	unique_board_moves.append(board.duplicate(true))
	amount_of_same.append(1)


func restart_pressed():
	board = []
	board.append([4,2,3,5,6,3,2,4])
	board.append([1,1,1,1,1,1,1,1])
	board.append([0,0,0,0,0,0,0,0])
	board.append([0,0,0,0,0,0,0,0])
	board.append([0,0,0,0,0,0,0,0])
	board.append([0,0,0,0,0,0,0,0])
	board.append([-1,-1,-1,-1,-1,-1,-1,-1])
	board.append([-4,-2,-3,-5,-6,-3,-2,-4])
	
	white = true
	state = false
	moves = []
	promotion_square = null
	white_castle_left = false
	white_castle_right = false
	black_castle_left = false
	black_castle_right = false
	en_passant = null
	white_king_pos = Vector2(0,4)
	black_king_pos = Vector2(7,4)
	fifty_move_rule = 0
	unique_board_moves = []
	amount_of_same = []
	
	win_message.visible = false
	restart.visible = false
	
	display_board()
