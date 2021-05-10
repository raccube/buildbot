require 'sidekiq/web'
require_relative 'server'

require 'securerandom'
use Rack::Session::Cookie, secret: SecureRandom.hex(32), same_site: true, max_age: 86400

run Rack::URLMap.new(
  '/' => BuildBotApp.new,
  '/sidekiq' => Sidekiq::Web.new
)
