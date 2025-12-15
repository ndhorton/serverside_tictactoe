# frozen_string_literal: true

# Keep track of and query board Square state
class Square
  INITIAL_MARKER = ' '

  attr_accessor :marker

  def initialize(square_state = nil)
    @marker = square_state.nil? ? INITIAL_MARKER : square_state
  end

  def marked?
    marker != INITIAL_MARKER
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end
end
