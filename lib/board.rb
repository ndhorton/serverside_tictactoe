# frozen_string_literal: true

# require_relative 'square'

# Keep track of and query board state
class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns
                  [[1, 5, 9], [3, 5, 7]]              # diagonals

  attr_reader :initial_marker
  attr_accessor :human_marker, :computer_marker, :active_turn

  # We need to modify this such that we can instantiate a Board from
  # an existing board state
  def initialize(human_marker,
                 computer_marker,
                 active_turn,
                 board_state = nil)
    @initial_marker = Square::INITIAL_MARKER
    @squares = {}
    @human_marker = human_marker
    @computer_marker = computer_marker
    @active_turn = active_turn
    reset_squares(board_state)
  end

  def [](key)
    @squares[key]
  end

  def []=(key, marker)
    @squares[key].marker = marker
  end

  # This is needed for the minimax simulations.
  def computer_turn?
    active_turn == :computer
  end

  def computer_won?
    winning_marker == computer_marker
  end

  def dump_board_state
    (1..9).map { |key| @squares[key].to_s }
  end

  def empty_squares
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def end_state?
    someone_won? || full?
  end

  def full?
    empty_squares.empty?
  end

  # This is needed for the minimax simultations.
  def human_turn?
    active_turn == :human
  end

  def human_won?
    winning_marker == human_marker
  end

  def middle_square_open?
    @squares[5].unmarked?
  end

  def open_square(marker)
    WINNING_LINES.each do |line|
      markers = @squares.values_at(*line).map(&:marker)
      next unless markers.count(marker) == 2 &&
                  markers.count(initial_marker) == 1

      empty_index = markers.index { |sq| sq != marker }
      return line[empty_index]
    end
    nil
  end

  def someone_won?
    !!winning_marker
  end

  def tie?
    full? && !someone_won?
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      return squares.first.marker if three_identical_markers?(squares)
    end
    nil
  end

  def reset_squares(board_state)
    if board_state.nil?
      (1..9).each { |key| @squares[key] = Square.new }
    else
      (1..9).each { |key| @squares[key] = Square.new(board_state[key - 1]) }
    end
  end

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != 3

    markers.min == markers.max
  end
end
