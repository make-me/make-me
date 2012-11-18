#!/usr/bin/env ruby

require 'bundler'
Bundler.require

post '/make' do
  stl_url = params[:url]
  puts "Grabbing #{stl_url} into data/print.stl"
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
