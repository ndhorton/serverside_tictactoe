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

  def admin_session
    { 'rack.session' => { username: 'admin' } }
  end

  def session
    last_request.env['rack.session']
  end

  def test_home_page
    get '/'

    assert_equal 302, last_response.status

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Tic Tac Toe'
    assert_includes last_response.body, 'Please sign up or sign in'
    assert_includes last_response.body, 'Sign Up'
    assert_includes last_response.body, 'Sign In'
  end

  def test_home_page_signed_in
    get '/'

    assert_equal 302, last_response.status

    get last_response['Location'], {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Hi there, admin! Welcome to Tic Tac Toe!'
    assert_includes last_response.body, 'New Game'
    assert_includes last_response.body, 'Sign Out'
  end

  def test_sign_in_page
    get '/users/signin'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Sign In'
    assert_includes last_response.body, 'Please enter your login credentials'
    assert_includes last_response.body, '<form'
    assert_includes last_response.body, 'Username:'
    assert_includes last_response.body, 'Password:'
  end

  def test_sign_up_page
    get '/users/signup'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Sign Up'
    assert_includes last_response.body, 'Please choose a username and password'
    assert_includes last_response.body, '<form'
    assert_includes last_response.body, 'Username:'
    assert_includes last_response.body, 'Password:'
  end

  def test_sign_out
    get '/'

    assert_equal 302, last_response.status

    get last_response['Location'], {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Hi there, admin! Welcome to Tic Tac Toe!'
    assert_includes last_response.body, 'Sign Out'

    get '/users/signout', {}, admin_session

    assert_equal 302, last_response.status
    assert_nil session[:username]
    assert_equal session[:message], 'You have been signed out.'

    get last_response['Location']

    assert_equal 302, last_response.status

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'You have been signed out.'
    assert_includes last_response.body, 'Please sign up or sign in'
    assert_includes last_response.body, 'Sign Up'
    assert_includes last_response.body, 'Sign In'
  end

  def test_game_page
    get '/game', {}, admin_session

    assert_equal 200, last_response.status
    refute_nil session[:game_state]
    assert_includes last_response.body, '<table'
    assert_includes last_response.body, '<div data-position'
  end

  def test_game_over_page_tie
    get '/game/over', {}, { 'rack.session' => {
      username: 'admin',
      game_state: {
        human_marker: 'X',
        active_turn: :human,
        board_state: %w[O X X X X O O O X]
      }
    } }

    get '/game/over', {}, admin_session

    assert_equal 200, last_response.status

    assert_includes last_response.body, '<table'
    assert_includes last_response.body, "It's a tie!"
  end

  def test_game_over_page_human_wins
    get '/game/over', {}, { 'rack.session' => {
      username: 'admin',
      game_state: {
        human_marker: 'X',
        active_turn: :human,
        board_state: ['X', 'O', 'X', ' ', 'X', ' ', 'X', ' ', 'O']
      }
    } }

    assert_equal 200, last_response.status

    assert_includes last_response.body, '<table'
    assert_includes last_response.body, 'You won!'
  end

  def test_game_over_page_computer_wins
    get '/game/over', {}, { 'rack.session' => {
      username: 'admin',
      game_state: {
        human_marker: 'X',
        active_turn: :human,
        board_state: ['O', 'X', 'O', ' ', 'O', ' ', 'O', ' ', 'X']
      }
    } }

    assert_equal 200, last_response.status

    assert_includes last_response.body, '<table'
    refute_includes last_response.body, 'You'
    assert_includes last_response.body, 'won!'
  end
end
