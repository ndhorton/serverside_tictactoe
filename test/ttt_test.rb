# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative '../ttt'

class TicTacToeTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
end
