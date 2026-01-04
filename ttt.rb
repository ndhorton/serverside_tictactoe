# frozen_string_literal: true

require 'bcrypt'
require 'securerandom'
require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/reloader' if development?
require 'tilt/erubi'
require 'yaml'

require_relative 'lib/tttgame'

def credentials_pathname
  if ENV['RACK_ENV'] == 'test'
    # rubocop:disable Style/ExpandPathArguments
    File.expand_path('../test/users.yaml', __FILE__)
    # rubocop:enable Style/ExpandPathArguments
  else
    # rubocop:disable Style/ExpandPathArguments
    File.expand_path('../users.yaml', __FILE__)
    # rubocop:enable Style/ExpandPathArguments
  end
end

def credentials_valid?(username, password)
  credentials = load_user_credentials

  credentials.key?(username) &&
    BCrypt::Password.new(credentials[username]) == password
end

def encrypt(password)
  BCrypt::Password.create(password).to_s
end

def load_user_credentials
  File.exist?(credentials_pathname) ? YAML.load_file(credentials_pathname) : {}
end

def load_user_scores
  File.exist?(user_scores_pathname) ? YAML.load_file(user_scores_pathname) : {}
end

def require_user_signin
  return if user_signed_in?

  session[:message] = 'You must be signed in to do that.'
  redirect '/'
end

def save_user_credentials(credentials)
  File.write(credentials_pathname, YAML.dump(credentials))
end

def save_user_scores(user_scores)
  File.write(user_scores_pathname, YAML.dump(user_scores))
end

def user_scores_pathname
  if ENV['RACK_ENV'] == 'test'
    # rubocop:disable Style/ExpandPathArguments
    File.expand_path('../test/scoreboard.yaml', __FILE__)
    # rubocop:enable Style/ExpandPathArguments
  else
    # rubocop:disable Style/ExpandPathArguments
    File.expand_path('../scoreboard.yaml', __FILE__)
    # rubocop:enable Style/ExpandPathArguments
  end
end

def user_exists?(username)
  credentials = load_user_credentials
  credentials.key?(username)
end

def user_signed_in?
  !!session[:username]
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
  redirect '/home'
end

get '/home' do
  @user_scores = load_user_scores

  erb :home
end

get '/users/signup' do
  erb :signup
end

get '/users/signin' do
  erb :signin
end

post '/users/signup' do
  username = params[:username].strip
  password = params[:password]

  if username.empty?
    session[:message] = 'Username cannot be blank.'
    erb :signup
  elsif password.empty?
    session[:message] = 'Password cannot be blank.'
    @previous_username = username
    erb :signup
  elsif user_exists?(username)
    session[:message] = 'A user with that name already exists. ' \
                        'Please choose another.'
    @previous_username = username
    erb :signup
  else
    credentials = load_user_credentials
    credentials[username] = encrypt(password)
    save_user_credentials(credentials)
    session[:message] = 'Account created.'
    redirect '/'
  end
end

post '/users/signin' do
  username = params[:username].strip
  password = params[:password]

  if username.empty?
    session[:message] = 'Username cannot be blank.'
    erb :signin
  elsif password.empty?
    session[:message] = 'Password cannot be blank.'
    @previous_username = username
    erb :signin
  elsif !credentials_valid?(username, password)
    session[:message] = 'The username and password do not match.'
    @previous_username = username
    erb :signin
  else
    session[:username] = username
    redirect '/'
  end
end

get '/users/signout' do
  require_user_signin

  session[:username] = nil
  session[:message] = 'You have been signed out.'
  redirect '/'
end

get '/users/scoreboard' do
  @user_scores = load_user_scores

  erb :scoreboard
end

get '/game/settings' do
  require_user_signin

  erb :settings
end

post '/game/settings' do
  require_user_signin

  first_turn = params[:first_turn].strip.to_sym
  opponent = params[:opponent].strip

  human_marker = (first_turn == :human ? 'X' : 'O')
  game_state = TTTGame.new_game(human_marker, first_turn, opponent)
  if first_turn == :computer
    computer_marker = (human_marker == 'X' ? 'O' : 'X')
    board = TTTGame.deserialize_board(game_state)
    computer_opponent = TTTGame.deserialize_opponent(game_state)
    computer_move = computer_opponent.choose(board)
    board[computer_move] = computer_marker
    game_state[:board_state] = board.dump_board_state
  end
  session[:game_state] = game_state
  redirect '/game'
end

get '/game' do
  require_user_signin

  @game_state = session[:game_state]

  erb :game
end

# this needs to be modified for the logic that updates the scoreboard datastore
get '/game/over' do
  require_user_signin

  @game_state = session[:game_state]
  redirect '/' if @game_state.nil?
  board = TTTGame.deserialize_board(@game_state)
  user_scores = load_user_scores

  if board.human_won?
    username = session[:username]
    user_scores[username] = (user_scores[username] || 0) + 1
    save_user_scores(user_scores)
    erb :layout, layout: false do
      erb :human_won do
        erb :end_state
      end
    end
  elsif board.computer_won?
    opponent = @game_state[:opponent]
    user_scores[opponent] = (user_scores[opponent] || 0) + 1
    save_user_scores(user_scores)
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

post '/game/:human_choice' do
  require_user_signin

  @game_state = session[:game_state]
  redirect '/' if @game_state.nil?
  board = TTTGame.deserialize_board(@game_state)

  # human moves
  board[params[:human_choice].to_i] = @game_state[:human_marker]

  # if human move completed the board, we return early 'end'
  if board.end_state?
    @game_state[:board_state] = board.dump_board_state
    session[:game_state] = @game_state
    content_type :json
    halt({ status: 'end' }.to_json)
  end

  # computer moves
  @opponent = TTTGame.deserialize_opponent(@game_state)
  computer_move = @opponent.choose(board)
  board[computer_move] = @game_state[:computer_marker]

  # if computer move completed the board, we return early 'end_after'
  if board.end_state?
    @game_state[:board_state] = board.dump_board_state
    session[:game_state] = @game_state
    content_type :json
    halt({ status: 'end_after' }.to_json)
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
