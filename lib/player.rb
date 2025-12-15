# frozen_string_literal: true

# Virtual class for derived computer player classes.
class Player
  attr_reader :name
  attr_accessor :marker
end

# Hal is the hardest computer opponent. Hal uses the minimax algorithm.
class Hal < Player
  # rubocop:disable Lint/MissingSuper
  def initialize
    @name = 'Hal'
    @choice = nil
  end
  # rubocop:enable Lint/MissingSuper

  def choose(board)
    # Guard clause prevents long think-time on first move
    return [9, 5].sample if board.empty_squares.size == 9

    minimax(board)
    @choice
  end

  private

  def appropriate_marker(board)
    board.computer_turn? ? board.computer_marker : board.human_marker
  end

  def change_board_state!(board, square)
    board[square] = appropriate_marker(board)
    reverse_active_turn!(board)
  end

  def min_or_max(board, squares, scores)
    if board.computer_turn?
      max_score_index = scores.each_with_index.to_a.max.last
      @choice = squares[max_score_index]
      scores[max_score_index]
    else
      min_score_index = scores.each_with_index.min.last
      @choice = squares[min_score_index]
      scores[min_score_index]
    end
  end

  def minimax(board, depth = 0)
    return score(board, depth) if board.end_state?

    scores = []
    squares = board.empty_squares.each do |square|
      change_board_state!(board, square)
      scores << minimax(board, depth + 1)
      revert_board_state!(board, square)
    end

    min_or_max(board, squares, scores)
  end

  def reverse_active_turn!(board)
    computer_active = board.computer_turn?
    board.active_turn = (computer_active ? :human : :computer)
  end

  def revert_board_state!(board, square)
    board[square] = board.initial_marker
    reverse_active_turn!(board)
  end

  def score(board, depth)
    if board.computer_won?
      10 - depth
    elsif board.human_won?
      depth - 10
    else
      0
    end
  end
end
