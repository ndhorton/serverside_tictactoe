# frozen_string_literal: true

require 'bcrypt'
require 'securerandom'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubi'
require 'yaml'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(64)
end

get '/' do
  '<html><h1>Tic Tac Toe</h1></html>'
end
