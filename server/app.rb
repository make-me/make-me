#!/usr/bin/env ruby

require 'bundler'
require 'sinatra/base'
require './server/lib/download'

module PrintMe
  class App < Sinatra::Base
    LOCK_FILE = 'printing.lock'

    post '/print' do
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

    get '/locked' do
      if File.exist(LOCK_FILE)
        status 423
        File.open(LOCK_FILE, 'r') { |f| f.read }
      else
        status 200
        "Unlocked"
      end
    end

    post '/unlock' do
      File.delete(LOCK_FILE)
      status 200
      "Lock cleared!"
    end
  end
end
