#!/usr/bin/env ruby

require 'bundler'
require 'sinatra'
require 'sinatra-basicauth'
require_relative 'lib/download'

module PrintMe
  class App < Sinatra::Base
    LOCK_FILE = 'printing.lock'
    PID_FILE  = 'tmp/make.pid'
    LOG_FILE  = 'tmp/make.log'

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

      out_name = 'snap_' + Time.now.to_i.to_s + ".jpg"
      out_dir = File.join(File.dirname(__FILE__), "public")

      Process.wait Process.spawn(imagesnap, File.join(out_dir, out_name))

      redirect out_name
    end

    ## Routes/Authed
    post '/print' do
      require_basic_auth
      if File.exist?(LOCK_FILE)
        reason = File.open(LOCK_FILE, 'r') { |f| f.read }
        halt 423, reason
      else
        File.open(LOCK_FILE, 'w') { |f| f.write "Currently printing" }
      end

      stl_url  = params[:url]
      stl_file = 'data/print.stl'
      PrintMe::Download.new(stl_url, stl_file).fetch
      makefile = File.join(File.dirname(__FILE__), '..', 'Makefile')
      make_stl = [ "make", "--file=#{makefile}",
                   "#{File.dirname(stl_file)}/#{File.basename(stl_file, '.stl')}",
                   "| tee #{LOG_FILE}"].join " "

      begin
        Timeout::timeout(5) do
          pid = Process.spawn(make_stl)
          File.open(PID_FILE, 'w') { |f| f.write pid }
          Process.wait pid
          status 500
          "Process died within 5 seconds with exit status #{$?.exitstatus}"
        end
      rescue Timeout::Error
        status 200
        "Looks like it's printing correctly"
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
