# frozen_string_literal: true

require 'bcrypt'
require 'securerandom'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubi'
require 'yaml'

require_relative 'lib/tttgame'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(64)
end

helpers do
  def visible_space(marker)
    marker.sub(/\s/, '&nbsp;')
  end
end

get '/' do
  redirect '/game/new'
end

get '/game/new' do
  @game_state = TTTGame.new_game('X', :human, 'Sonny')
  session[:game_state] = @game_state
  erb :player_chooses
end

get '/game/over' do
  @game_state = session[:game_state]
  redirect '/game/new' if @game_state.nil?
  board = TTTGame.deserialize_board(@game_state)
  if board.human_won?
    erb :human_won
  elsif board.computer_won?
    erb :computer_won
  else
    erb :tie
  end
end

get '/game/:human_choice' do
  @game_state = session[:game_state]
  redirect '/game/new' if @game_state.nil?
  board = TTTGame.deserialize_board(@game_state)
  @opponent = TTTGame.deserialize_opponent(@game_state)

  # human moves
  board[params[:human_choice].to_i] = @game_state[:human_marker]

  if board.end_state?
    @game_state[:board_state] = board.dump_board_state
    session[:game_state] = @game_state
    redirect '/game/over'
  end

  # computer moves
  board[@opponent.choose(board)] = @game_state[:computer_marker]

  # save current board state in the session game state
  # and instance variable for view
  @game_state[:board_state] = board.dump_board_state
  session[:game_state] = @game_state

  redirect '/game/over' if board.end_state?

  erb :player_chooses
end
