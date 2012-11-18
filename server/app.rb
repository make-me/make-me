#!/usr/bin/env ruby

require 'bundler'
require 'sinatra/base'

module PrintMe
  class App < Sinatra::Base
    post '/print' do
      stl_url = params[:url]
      begin
        `curl -o "data/print.stl" #{stl_url}`
        if system('make data/print')
          status 200
        else
          status 500
        end
      ensure
        `rm data/print.stl`
      end
    end
  end
end
