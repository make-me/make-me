#!/usr/bin/env ruby

require 'bundler'
require 'sinatra/base'

module PrintMe
  class App < Sinatra::Base
    post '/print' do
      lock_file = File.new __FILE__

      unless lock_file.flock File::LOCK_EX | File::LOCK_NB
        halt 423, "Currently printing!"
      end

      stl_url = params[:url]
      begin
        `curl -o "data/print.stl" #{stl_url}`
        if system('make data/print')
          status 201
          "Thing printed! Go pick it up"
        else
          status 500
          "Failed to print"
        end
      ensure
        status 500
        lock_file.flock File::LOCK_UN
        `rm data/print.stl`
        "Broke during download & print"
      end
    end
  end
end
