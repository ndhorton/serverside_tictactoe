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

get '/' do
  session[:game] = TTTGame.new if session[:game].nil?
end
