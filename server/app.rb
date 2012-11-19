#!/usr/bin/env ruby

require 'bundler'
require 'sinatra'
require 'sinatra-basicauth'
require './server/lib/download'

module PrintMe
  class App < Sinatra::Base
    LOCK_FILE = 'printing.lock'

    ## Config
    set :static, true

    basic_auth do
      realm "The 3rd Dimension"
      username 'hubot'
      password 'isalive'
    end

    ## Routes/Public
    get '/' do
      status 200
      "make_me version F.U-bro"
    end

    get '/photo' do
      imagesnap = File.join(File.dirname(__FILE__), '..', 'vendor', 'imagesnap', 'imagesnap')
      rd, wr = IO.pipe
      pid = Process.spawn(imagesnap, '-', :out  => wr)
      wr.close

      image = rd.read
      Process.wait(pid)
      content_type 'image/jpeg'
      image
    end

    ## Routes/Authed
    post '/print' do
      require_basic_auth
      if File.exist?(LOCK_FILE)
        reason = File.open(LOCK_FILE, 'r') { |f| f.read }
        halt 423, reason
      else
        File.open(LOCK_FILE, 'w+') { |f| f.write "Currently printing" }
      end

      stl_url = params[:url]
      begin
        PrintMe::Download.new(stl_url, 'data/print.stl').fetch
        if system('make data/print')
          status 201
          "Thing printed! Go pick it up"
        else
          status 500
          "Failed to print"
        end
      ensure
        File.delete('data/print.stl')
      end
    end

    get '/lock' do
      require_basic_auth
      if File.exist?(LOCK_FILE)
        status 423
        File.open(LOCK_FILE, 'r') { |f| f.read }
      else
        status 200
        "Unlocked"
      end
    end

    post '/unlock' do
      require_basic_auth
      File.delete(LOCK_FILE) if File.exist?(LOCK_FILE)
      status 200
      "Lock cleared!"
    end
  end
end
