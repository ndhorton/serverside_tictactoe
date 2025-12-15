# frozen_string_literal: true

require_relative 'board'
require_relative 'square'
require_relative 'player'

# receive request
# New game, new board
board = Board.new('X', 'O', :human)
hal = Hal.new

# player moves
board[5] = 'X'
# computer moves
computer_choice = hal.choose(board)
board[computer_choice] = 'O'

# serialize board
board_state = board.dump_board_state

# store board_state and other parameters in session
# generate response
# receive request

new_board = Board.new('X', 'O', :computer, board_state)
p new_board.dump_board_state
