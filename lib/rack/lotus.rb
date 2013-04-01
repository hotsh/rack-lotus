require 'sinatra'

module Rack
  # Contains the various routes used by the federation.
  class Lotus < Sinatra::Base
    require 'lotus'
    require 'mongo_mapper'
  end
end

require 'rack/lotus/subscriptions'
require 'rack/lotus/activities'
require 'rack/lotus/people'
require 'rack/lotus/feeds'
require 'rack/lotus/api'

Dir[File.join(File.dirname(__FILE__), "lotus", "models", '*.rb')].each {|file| require file }
