# frozen_string_literal: true

require 'sinatra'
require 'json'
require 'git'
require 'sidekiq'
require_relative 'build_worker'

PLATFORMS = %w(odroid rpi3 rpi4)

class BuildBotApp < Sinatra::Base
  get '/', provides: :json do
    "there's a raccoon in my engine".to_json
  end

  post '/build' do
    request.body.rewind
    payload_body = request.body.read
    verify_signature(payload_body)
    push = JSON.parse(payload_body)

    repo_dir = `mktemp -du`.chomp
    puts "Cloning to #{repo_dir}"
    clone_url = push.dig('repository', 'clone_url')
    repo = Git.clone(clone_url, repo_dir)
    repo.reset_hard(push['after'])

    commitish = push['after'][0...7]
    PLATFORMS.each do |platform|
      BuildWorker.perform_async(repo_dir, platform, commitish)
    end
  end

  def verify_signature(payload_body)
    signature = "sha256=#{OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), ENV['SECRET_TOKEN'], payload_body)}"
    halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature,
                                                                           request.env['HTTP_X_HUB_SIGNATURE_256'])
  end
end
