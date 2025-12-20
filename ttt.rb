# frozen_string_literal: true

require 'bcrypt'
require 'securerandom'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubi'
require 'yaml'

require_relative 'lib/tttgame'

def end_state_page(game_state)
  @game_state = game_state
  board = game_state[:board_state]
  if board.human_won?
    erb :layout, layout: false do
      erb :human_won do
        erb :end_state
      end
    end
  elsif board.computer_won?
    erb :layout, layout: false do
      erb :computer_won do
        erb :end_state
      end
    end
  else
    erb :layout, layout: false do
      erb :tie do
        erb :end_state
      end
    end
  end
end

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
  redirect '/game'
end

get '/game' do
  @game_state = TTTGame.new_game('X', :human, 'Sonny')
  session[:game_state] = @game_state
  erb :game
end

# get '/game/over' do
#   @game_state = session[:game_state]
#   redirect '/game/new' if @game_state.nil?
#   board = TTTGame.deserialize_board(@game_state)
#   if board.human_won?
#     erb :layout, layout: false do
#       erb :human_won do
#         erb :end_state
#       end
#     end
#   elsif board.computer_won?
#     erb :layout, layout: false do
#       erb :computer_won do
#         erb :end_state
#       end
#     end
#   else
#     erb :layout, layout: false do
#       erb :tie do
#         erb :end_state
#       end
#     end
#   end
# end

# get '/game/:human_choice' do
#   @game_state = session[:game_state]
#   redirect '/game/new' if @game_state.nil?
#   board = TTTGame.deserialize_board(@game_state)
#   @opponent = TTTGame.deserialize_opponent(@game_state)
#
#   # human moves
#   board[params[:human_choice].to_i] = @game_state[:human_marker]
#
#   if board.end_state?
#     @game_state[:board_state] = board.dump_board_state
#     session[:game_state] = @game_state
#     redirect '/game/over'
#   end
#
#   # computer moves
#   board[@opponent.choose(board)] = @game_state[:computer_marker]
#
#   # save current board state in the session game state
#   # and instance variable for view
#   @game_state[:board_state] = board.dump_board_state
#   session[:game_state] = @game_state
#
#   redirect '/game/over' if board.end_state?
#
#   erb :player_chooses
# end

post '/game/:human_choice' do
  @game_state = session[:game_state]
  redirect '/game/new' if @game_state.nil?
  board = TTTGame.deserialize_board(@game_state)

  # human moves
  board[params[:human_choice].to_i] = @game_state[:human_marker]

  if board.end_state?
    @game_state[:board_state] = board.dump_board_state

    halt({ status: 'end',
           content: end_state_page(@game_state) }.to_json)
  end

  # computer moves
  @opponent = TTTGame.deserialize_opponent(@game_state)
  computer_move = @opponent.choose(board)
  board[computer_move] = @game_state[:computer_marker]

  if board.end_state?
    @game_state[:board_state] = board.dump_board_state

    halt({ status: 'end',
           content: end_state_page(@game_state) }.to_json)
  end

  # save current board state in the session
  @game_state[:board_state] = board.dump_board_state
  session[:game_state] = @game_state

  # Now we need to send back the computer's move and marker
  # serialized as a JSON object
  content_type :json
  {
    status: 'continue',
    computer_move: computer_move,
    computer_marker: @game_state[:computer_marker]
  }.to_json
end
