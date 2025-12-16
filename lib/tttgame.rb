# frozen_string_literal: true

require_relative 'board'
require_relative 'square'
require_relative 'player'

# Game logic helper methods
module TTTGame
  class << self
    def deserialize_board(game_state)
      human_marker = game_state[:human_marker]
      active_turn = game_state[:active_turn]
      board_state = game_state[:board_state]
      Board.new(human_marker, active_turn, board_state)
    end

    def deserialize_opponent(game_state)
      case game_state[:opponent]
      when 'R2D2'   then R2D2.new
      when 'Sonny'  then Sonny.new
      when 'Hal'    then Hal.new
      end
    end

    def new_game(human_marker = 'X', active_turn = :human, opponent = 'Hal')
      computer_marker = (human_marker == 'X' ? 'O' : 'X')
      {
        board_state: Board.new(human_marker, active_turn).dump_board_state,
        human_marker: human_marker,
        computer_marker: computer_marker,
        active_turn: active_turn,
        opponent: opponent
      }
    end
  end
end
